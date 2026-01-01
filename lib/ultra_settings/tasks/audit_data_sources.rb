# frozen_string_literal: true

module UltraSettings
  module Tasks
    class AuditDataSources
      class << self
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

        def env_vars_without_defaults
          no_default_env_var_fields = []
          each_configuration do |config|
            each_field_using_source(config, :env) do |field|
              value = default_config_value(config, field)
              if value.nil?
                no_default_env_var_fields << [config.class.name, field.name, field.env_var, value]
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
