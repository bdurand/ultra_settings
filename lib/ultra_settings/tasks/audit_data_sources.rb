# frozen_string_literal: true

module UltraSettings
  module Tasks
    class AuditDataSources
      class << self
        # Find environment variables that are set but have the same value as their default.
        # These environment variables could potentially be removed since they're not changing behavior.
        #
        # @return [Array<Array<(String, Object)>>] An array of tuples containing environment variable names and their default values
        def unnecessary_env_vars
          env_vars_at_default = []
          each_configuration do |config|
            each_field_using_source(config, :env) do |field|
              value = config[field.name]
              default_value = default_config_value(config, field)
              env_vars_at_default << [field.env_var, default_value] if default_value == value
            end
          end
          env_vars_at_default
        end

        # Find runtime settings that are set but have the same value as their default.
        # These runtime settings could potentially be removed since they're not changing behavior.
        #
        # @return [Array<Array<(String, Object)>>] An array of tuples containing runtime setting names and their default values
        def unnecessary_runtime_settings
          unnecessary_runtime_settings = []
          each_configuration do |config|
            each_field_using_source(config, :settings) do |field|
              value = config[field.name]
              default_value = default_config_value(config, field)
              unnecessary_runtime_settings << [field.runtime_setting, default_value] if default_value == value
            end
          end
          unnecessary_runtime_settings
        end

        # Find environment variables that could be moved to runtime settings.
        # These are non-default environment variable values where a runtime setting is also available.
        #
        # @return [Array<Array<(String, String, Object)>>] An array of tuples containing environment variable name, runtime setting name, and current value
        def env_vars_can_be_runtime_setting
          env_vars_can_be_runtime = []
          each_configuration do |config|
            each_field_using_source(config, :env) do |field|
              value = config[field.name]
              default_value = default_config_value(config, field)
              next unless field.runtime_setting && value != default_value

              env_vars_can_be_runtime << [field.env_var, field.runtime_setting, value]
            end
          end
          env_vars_can_be_runtime
        end

        # Find environment variables being used that don't have default values defined.
        # These configurations require an environment variable to be set.
        #
        # @return [Array<Array<(String, Symbol, String, nil)>>] An array of tuples containing class name, field name, environment variable name, and nil value
        def env_vars_without_default
          no_default_env_var_fields = []
          each_configuration do |config|
            each_field_using_source(config, :env) do |field|
              value = default_config_value(config, field)
              if value.nil?
                no_default_env_var_fields << [config.class.name, field.name, field.env_var, config[field.name]]
              end
            end
          end
          no_default_env_var_fields
        end

        private

        def each_configuration(&_block)
          UltraSettings::Configuration.descendant_configurations.each do |config_class|
            config = config_class.instance
            yield config
          end
        end

        def each_field_using_source(config, source, &_block)
          config.class.fields.each do |field|
            next if field.secret?
            next unless config.__source__(field.name) == source

            yield field
          end
        end

        def default_config_value(config, field)
          yaml_value = config.__value_from_source__(field.name, :yaml)
          default_value = config.__value_from_source__(field.name, :default)
          yaml_value || default_value
        end
      end
    end
  end
end
