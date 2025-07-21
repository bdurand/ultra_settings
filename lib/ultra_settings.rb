# frozen_string_literal: true

require "erb"
require "yaml"
require "time"
require "pathname"
require "singleton"
require "digest"
require "uri"

require_relative "ultra_settings/configuration"
require_relative "ultra_settings/coerce"
require_relative "ultra_settings/config_helper"
require_relative "ultra_settings/field"
require_relative "ultra_settings/rack_app"
require_relative "ultra_settings/view_helper"
require_relative "ultra_settings/web_view"
require_relative "ultra_settings/application_view"
require_relative "ultra_settings/configuration_view"
require_relative "ultra_settings/uninitialized_runtime_settings"
require_relative "ultra_settings/yaml_config"
require_relative "ultra_settings/version"

if defined?(Rails::Railtie)
  require_relative "ultra_settings/railtie"
end

# This is the root namespace for UltraSettings. You can add configurations to
# this namespace using the add method.
#
# @example
#   UltraSettings.add(:test)
#   UltraSettings.test # => TestConfiguration.instance
module UltraSettings
  VALID_NAME__PATTERN = /\A[a-z_][a-zA-Z0-9_]*\z/

  @configurations = {}
  @mutex = Mutex.new
  @runtime_settings = nil
  @runtime_settings_url = nil

  class << self
    # Adds a configuration to the root namespace. The configuration will be
    # available as a method on the UltraSettings module with the provide name.
    #
    # @param name [Symbol, String] The name of the configuration.
    # @param klass [Class, String] The class of the configuration. If this is not
    #   provided then the class will be inferred from the name by camelizing the
    #   name and appending "Configuration" to get the class name.
    # @return [void]
    def add(name, klass = nil)
      name = name.to_s
      unless name.match?(VALID_NAME__PATTERN)
        raise ArgumentError.new("Invalid configuration name: #{name.inspect}")
      end

      class_name = klass&.to_s
      class_name ||= "#{classify(name)}Configuration"

      @mutex.synchronize do
        @configurations[name] = class_name

        eval <<-RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            __load_config__(#{name.inspect}, #{class_name.inspect})
          end
        RUBY
      end
    end

    # Returns true if the provided class has been added as a configuration.
    #
    # @param class_name [Class, String] The name of the configuration class.
    # @return [Boolean]
    def added?(class_name)
      @configurations.values.collect(&:to_s).include?(class_name.to_s)
    end

    # Control if settings can be loaded from environment variables. By default
    # environment variables are enabled. This can also be disabled on
    # individual Configuration classes.
    #
    # @param value [Boolean] Whether or not to load settings from environment variables.
    # @return [void]
    def environment_variables_disabled=(value)
      Configuration.environment_variables_disabled = !!value
    end

    # Control if settings can be loaded from runtime settings. By default
    # runtime settings are enabled. This can also be disabled on individual
    # Configuration classes.
    #
    # @param value [Boolean] Whether or not to load settings from runtime settings.
    # @return [void]
    def runtime_settings_disabled=(value)
      Configuration.runtime_settings_disabled = !!value
    end

    # Control if settings can be loaded from YAML configuration files. By
    # default YAML configuration is enabled. This can also be disabled on
    # individual Configuration classes.
    #
    # @param value [Boolean] Whether or not to load settings from YAML configuration.
    # @return [void]
    def yaml_config_disabled=(value)
      Configuration.yaml_config_disabled = !!value
    end

    # Set the environment to use when loading YAML configuration files.
    # In a Rails application this will be the current Rails environment.
    # Defaults to "development".
    #
    # @param value [String] The environment name to use.
    def yaml_config_env=(value)
      Configuration.yaml_config_env = value
    end

    # Set the delimiter to use when determining environment variable names.
    # By default this is an underscore.
    #
    # @param value [String] The delimiter to use.
    # @return [void]
    def env_var_delimiter=(value)
      Configuration.env_var_delimiter = value.to_s
    end

    # Set the delimiter to use when determining setting names. By default
    # this is a period.
    #
    # @param value [String] The delimiter to use.
    def runtime_setting_delimiter=(value)
      Configuration.runtime_setting_delimiter = value.to_s
    end

    # Control if environment variable names should be upcased. By default
    # this is true.
    #
    # @param value [Boolean] Whether or not to upcase environment variable names.
    # @return [void]
    def env_var_upcase=(value)
      Configuration.env_var_upcase = !!value
    end

    # Control if setting names should be upcased. By default this is false.
    #
    # @param value [Boolean] Whether or not to upcase setting names.
    # @return [void]
    def runtime_setting_upcase=(value)
      Configuration.runtime_setting_upcase = !!value
    end

    # Set the directory to use when loading YAML configuration files.
    # In a Rails application this will be the config directory.
    # Otherwise it will be the current working directory.
    #
    # @param value [String, Pathname] The directory to use.
    # @return [void]
    def yaml_config_path=(value)
      Configuration.yaml_config_path = value.to_s
    end

    # Set the object to use for runtime settings. This can be any object that
    # responds to the [] method. If you are using the `super_settings` gem,
    # you can set this to `SuperSettings`.
    attr_writer :runtime_settings

    # Get the object to use for runtime settings.
    #
    # @return [Object, nil]
    # @api private
    def __runtime_settings__
      @runtime_settings
    end

    # Set the URL for changing runtime settings. If this is set, then a link to the
    # URL will be displayed in the web view for fields that support runtime settings.
    # The URL may contain a `${name}` placeholder that will be replaced with the name
    # of the setting.
    attr_writer :runtime_settings_url

    # Get the URL for changing runtime settings.
    #
    # @param name [String] The name of the setting.
    # @return [String, nil]
    # @api private
    def runtime_settings_url(name, type)
      url = @runtime_settings_url.to_s
      return nil if url.empty?

      url = url.gsub("${name}", URI.encode_www_form_component(name.to_s))
      url.gsub("${type}", URI.encode_www_form_component(type.to_s))
    end

    def fields_secret_by_default=(value)
      Configuration.fields_secret_by_default = value
    end

    # Explicitly set values for setting within a block. This is useful for testing
    # or other situations where you want hard code a specific set of values.
    #
    # @param settings [Hash] The settings to set.
    # @return [Object] The result of the block.
    def override!(settings, &block)
      settings = settings.to_a
      config_name, values = settings.first
      config_name = config_name.to_s
      other_settings = settings[1..-1]

      unless @configurations.include?(config_name)
        raise ArgumentError.new("Unknown configuration: #{config_name.inspect}")
      end

      config = send(config_name)
      config.override!(values) do
        if other_settings.empty?
          yield
        else
          override!(other_settings, &block)
        end
      end
    end

    # Get the names of all of the configurations that have been added.
    #
    # @return [Array<String>] The names of the configurations.
    # @api private
    def __configuration_names__
      @configurations.keys
    end

    private

    # Load a configuration class.
    def __load_config__(name, class_name)
      klass = @configurations[name]

      # Hook for Rails development mode to reload the configuration class.
      if klass && defined?(Rails.configuration.cache_classes) && !Rails.configuration.cache_classes
        klass = class_name if klass != constantize(class_name)
      end

      if klass.is_a?(String)
        klass = constantize(class_name)
        @mutex.synchronize do
          unless klass < Configuration
            raise TypeError.new("Configuration class #{class_name} does not inherit from UltraSettings::Configuration")
          end
          @configurations[name] = klass
        end
      end

      klass.instance
    end

    def classify(name)
      # Use the Rails classify method if it is available since it will
      # handle custom inflections.
      if name.respond_to?(:classify)
        name.classify
      else
        name.split("_").map(&:capitalize).join.gsub("/", "::")
      end
    end

    def constantize(class_name)
      class_name.split("::").reduce(Object) do |mod, name|
        mod.const_get(name)
      end
    end
  end
end
