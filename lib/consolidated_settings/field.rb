# frozen_string_literal: true

module ConsolidatedSettings
  class Field
    attr_reader :name
    attr_reader :type
    attr_reader :default
    attr_reader :env_var
    attr_reader :setting_name
    attr_reader :yaml_key
    attr_reader :env_var_prefix
    attr_reader :setting_prefix

    def initialize(
      name:,
      type: :string,
      default: nil,
      env_var: nil,
      setting_name: nil,
      yaml_key: nil,
      env_var_prefix: nil,
      setting_prefix: nil
    )
      @name = frozen_string(name)
      @type = type.to_sym
      @default = default&.dup.freeze
      @env_var = frozen_string(env_var)
      @setting_name = frozen_string(setting_name)
      @yaml_key = frozen_string(yaml_key)
      @env_var_prefix = frozen_string(env_var_prefix)
      @setting_prefix = frozen_string(setting_prefix)
    end

    def value(env: ENV, settings: SuperSettings, yaml_config: nil)
      val = fetch_value(env: env, settings: settings, yaml_config: yaml_config)
      val = @default if val.blank?
      coerce_value(val).freeze
    end

    private

    def fetch_value(env:, settings:, yaml_config:)
      value = env_value(name, @env_var) if env
      if value.blank?
        value = runtime_value(name, @setting_name) if settings
        if value.blank?
          value = yaml_value(name, @yaml_key, yaml_config) if yaml_config
        end
      end
      value
    end

    def coerce_value(value)
      return nil if value.nil?

      case type
      when :integer
        value.is_a?(Integer) ? value : value.to_s&.to_i
      when :float
        value.is_a?(Float) ? value : value.to_s&.to_f
      when :boolean
        SuperSettings::Coerce.boolean(value)
      when :datetime
        SuperSettings::Coerce.time(value)
      when :array
        Array(value).map(&:to_s)
      else
        value.to_s
      end
    end

    def env_value(name, env_var)
      env_var ||= "#{@env_var_prefix}#{name.upcase}"
      ENV[env_var.to_s]
    end

    def runtime_value(name, setting)
      setting ||= "#{@setting_prefix}#{name}"
      SuperSettings.get(setting.to_s)
    end

    def yaml_value(name, yaml_key, yaml_config)
      yaml_key ||= name
      yaml_config[yaml_key.to_s]
    end

    def frozen_string(value)
      value&.to_s&.dup&.freeze
    end
  end
end
