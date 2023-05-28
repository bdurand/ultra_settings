# frozen_string_literal: true

module UltraSettings
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
      default_if: nil,
      env_var: nil,
      setting_name: nil,
      yaml_key: nil,
      env_var_prefix: nil,
      setting_prefix: nil
    )
      @name = frozen_string(name)
      @type = type.to_sym
      @default = coerce_value(default).freeze
      @default_if = default_if
      @env_var = frozen_string(env_var)
      @setting_name = frozen_string(setting_name)
      @yaml_key = frozen_string(yaml_key)
      @env_var_prefix = frozen_string(env_var_prefix)
      @setting_prefix = frozen_string(setting_prefix)
    end

    def value(env: ENV, settings: SuperSettings, yaml_config: nil)
      val = fetch_value(env: env, settings: settings, yaml_config: yaml_config)
      val = coerce_value(val).freeze
      val = @default if use_default?(val)
      val
    end

    private

    def fetch_value(env:, settings:, yaml_config:)
      value = env_value(name, @env_var) if env
      value = nil if value == ""

      if value.nil? && settings
        value = runtime_value(name, @setting_name)
        value = nil if value == ""
      end

      if value.nil? && yaml_config
        value = yaml_value(name, @yaml_key, yaml_config)
        value = nil if value == ""
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
      when :symbol
        value.to_s.to_sym
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

    def use_default?(value)
      if value && @default_if
        @default_if.call(value)
      else
        value.nil?
      end
    end

    def frozen_string(value)
      value&.to_s&.dup&.freeze
    end
  end
end
