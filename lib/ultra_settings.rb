# frozen_string_literal: true

require "super_settings"

require_relative "ultra_settings/configuration"
require_relative "ultra_settings/field"
require_relative "ultra_settings/rack_app"
require_relative "ultra_settings/web_app"

# This is the root namespace for UltraSettings. You can add configurations to
# this namespace using the add method.
#
# @example
#   UltraSettings.add(:test)
#   UltraSettings.test # => TestConfiguration.instance
module UltraSettings
  @configurations = {}
  @mutex = Mutex.new

  class NonStaticValueError < StandardError
  end

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
      unless name.match?(/\A[a-z_][a-zA-Z0-9_]*\z/)
        raise ArgementError.new("Invalid configuration name: #{name.inspect}")
      end

      class_name = klass&.to_s
      class_name ||= "#{name.classify}Configuration"

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
    def setting_delimiter=(value)
      Configuration.setting_delimiter = value.to_s
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
    def setting_upcase=(value)
      Configuration.setting_upcase = !!value
    end

    # Set the directory to use when loading YAML configuration files. By
    # default this is the config directory in the Rails root.
    #
    # @param value [String, Pathname] The directory to use.
    # @return [void]
    def yaml_config_directory=(value)
      Configuration.yaml_config_directory = value.to_s
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

      if klass && !Rails.configuration.cache_classes
        klass = nil if klass != class_name.constantize
      end

      unless klass
        klass = class_name.constantize
        @mutex.synchronize do
          unless klass < Configuration
            raise TypeError.new("Configuration class #{class_name} does not inherit from UltraSettings::Configuration")
          end
          @configurations[name] = klass
        end
      end

      klass.instance
    end
  end
end
