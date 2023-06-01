# frozen_string_literal: true

module UltraSettings
  # Definition for a field on a configuration.
  class Field
    attr_reader :name
    attr_reader :type
    attr_reader :default
    attr_reader :default_if
    attr_reader :env_var
    attr_reader :setting_name
    attr_reader :yaml_key
    attr_reader :env_var_prefix
    attr_reader :env_var_upcase
    attr_reader :setting_prefix
    attr_reader :setting_upcase

    # @param name [String, Symbol] The name of the field.
    # @param type [Symbol] The type of the field.
    # @param default [Object] The default value of the field.
    # @param default_if [Proc] A proc that returns true if the default value should be used.
    # @param env_var [String, Symbol] The name of the environment variable to use for the field.
    # @param setting_name [String, Symbol] The name of the setting to use for the field.
    # @param yaml_key [String, Symbol] The name of the YAML key to use for the field.
    # @param env_var_prefix [String, Symbol] The prefix to use for the environment variable name.
    # @param env_var_upcase [Boolean] Whether or not to upcase the environment variable name.
    # @param setting_prefix [String, Symbol] The prefix to use for the setting name.
    # @param setting_upcase [Boolean] Whether or not to upcase the setting name.
    def initialize(
      name:,
      type: :string,
      default: nil,
      default_if: nil,
      env_var: nil,
      setting_name: nil,
      yaml_key: nil,
      env_var_prefix: nil,
      env_var_upcase: true,
      setting_prefix: nil,
      setting_upcase: false
    )
      @name = frozen_string(name)
      @type = type.to_sym
      @default = coerce_value(default).freeze
      @default_if = default_if
      @env_var = frozen_string(env_var)
      @setting_name = frozen_string(setting_name)
      @yaml_key = frozen_string(yaml_key)
      @env_var_prefix = frozen_string(env_var_prefix)
      @env_var_upcase = !!env_var_upcase
      @setting_prefix = frozen_string(setting_prefix)
      @setting_upcase = !!setting_upcase
    end

    # Get the value for the field from the passed in state.
    #
    # @param env [#[]] The environment variables.
    # @param settings [#[]] The runtime settings.
    # @param yaml_config [#[]] The YAML configuration.
    def value(env: nil, settings: nil, yaml_config: nil)
      val = fetch_value(env: env, settings: settings, yaml_config: yaml_config)
      val = coerce_value(val).freeze
      val = @default if use_default?(val)
      val
    end

    private

    def fetch_value(env:, settings:, yaml_config:)
      value = env_value(env) if env
      value = nil if value == ""

      if value.nil? && settings
        value = runtime_value(settings)
        value = nil if value == ""
      end

      if value.nil? && yaml_config
        value = yaml_value(yaml_config)
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

    def env_value(env)
      var_name = env_var
      if var_name.nil?
        var_name = "#{env_var_prefix}#{name}"
        var_name = var_name.upcase if env_var_upcase
      end
      env[var_name.to_s]
    end

    def runtime_value(settings)
      var_name = setting_name
      if var_name.nil?
        var_name = "#{setting_prefix}#{name}"
        var_name = var_name.upcase if setting_upcase
      end
      settings[var_name.to_s]
    end

    def yaml_value(yaml_config)
      key = (yaml_key || name)
      yaml_config[key.to_s]
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
