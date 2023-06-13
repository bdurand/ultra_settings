# frozen_string_literal: true

require "erb"
require "yaml"
require "time"
require "pathname"
require "singleton"

require_relative "ultra_settings/configuration"
require_relative "ultra_settings/coerce"
require_relative "ultra_settings/field"
require_relative "ultra_settings/rack_app"
require_relative "ultra_settings/web_view"
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
        raise ArgementError.new("Invalid configuration name: #{name.inspect}")
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

    attr_writer :runtime_settings

    def __runtime_settings__
      @runtime_settings ||= nil
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
