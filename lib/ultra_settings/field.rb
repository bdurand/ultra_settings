# frozen_string_literal: true

module UltraSettings
  # Definition for a field on a configuration.
  class Field
    attr_reader :name
    attr_reader :type
    attr_reader :description
    attr_reader :default
    attr_reader :default_if
    attr_reader :env_var
    attr_reader :setting_name
    attr_reader :yaml_key

    # @param name [String, Symbol] The name of the field.
    # @param type [Symbol] The type of the field.
    # @param description [String] The description of the field.
    # @param default [Object] The default value of the field.
    # @param default_if [Proc] A proc that returns true if the default value should be used.
    # @param env_var [String, Symbol] The name of the environment variable to use for the field.
    # @param setting_name [String, Symbol] The name of the setting to use for the field.
    # @param yaml_key [String, Symbol] The name of the YAML key to use for the field.
    def initialize(
      name:,
      type: :string,
      description: nil,
      default: nil,
      default_if: nil,
      env_var: nil,
      setting_name: nil,
      yaml_key: nil,
      static: false
    )
      @name = name.to_s.freeze
      @type = type.to_sym
      @description = description&.to_s&.freeze
      @default = coerce_value(default).freeze
      @default_if = default_if
      @env_var = env_var&.to_s&.freeze
      @setting_name = setting_name&.to_s&.freeze
      @yaml_key = yaml_key&.to_s&.freeze
      @static = !!static
    end

    # Get the value for the field from the passed in state.
    #
    # @param env [#[]] The environment variables.
    # @param settings [#[]] The runtime settings.
    # @param yaml_config [#[]] The YAML configuration.
    def value(env: nil, settings: nil, yaml_config: nil)
      fetch_value_and_source(env: env, settings: settings, yaml_config: yaml_config).first
    end

    def source(env: nil, settings: nil, yaml_config: nil)
      fetch_value_and_source(env: env, settings: settings, yaml_config: yaml_config).last
    end

    def static?
      @static
    end

    private

    def fetch_value_and_source(env:, settings:, yaml_config:)
      source = nil

      value = env[env_var] if env && env_var
      value = nil if value == ""
      if value.nil?
        value = settings[setting_name] if settings && setting_name
        value = nil if value == ""
        if value.nil?
          value = yaml_value(yaml_config)
          value = nil if value == ""
          source = :yaml unless value.nil?
        else
          source = :settings
        end
      else
        source = :env
      end

      value = coerce_value(value).freeze
      if use_default?(value)
        value = @default
        source = :default
      end

      [value, source]
    end

    def yaml_value(yaml_config)
      return nil unless yaml_config && yaml_key

      # TODO implement dot syntax
      yaml_config[yaml_key]
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

    def use_default?(value)
      if value && @default_if
        @default_if.call(value)
      else
        value.nil?
      end
    end
  end
end
