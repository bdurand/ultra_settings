# frozen_string_literal: true

module SuperConfig
  class Configuration
    extend Components

    ALLOWED_NAME_PATTERN = /\A[a-z_][a-zA-Z0-9_]*\z/
    ALLOWED_TYPES = [:string, :integer, :float, :boolean, :datetime, :array].freeze

    class << self
      def env_prefix
        @env_prefix ||= name.snakecase.tr("/", "_").upcase + "_"
      end

      attr_writer :env_prefix

      def configuration_file
        @configuration_file ||= (Rails.root + "config").join(*"#{name.snakecase}.yml".split("/"))
      end

      def configuration_file=(file)
        @configuration_file = (file.is_a?(Pathname) ? file : Rails.root + file)
      end

      def setting_prefix
        @env_prefix ||= name.snakecase.tr("/", ".") + "."
      end

      attr_writer :setting_prefix

      def define(name, type: :string, default: nil, static: false, setting: nil, env_var: nil, yaml_key: nil)
        name = name.to_s
        type = type.to_sym
        static = !!static

        unless name.match?(ALLOWED_NAME_PATTERN)
          raise ArgumentError.new("Invalid name: #{name.inspect}")
        end

        unless ALLOWED_TYPES.include?(type)
          raise ArgumentError.new("Invalid type: #{type.inspect}")
        end

        class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            get_setting(#{name.inspect}, type: #{type.inspect}, default: #{default.inspect}, static: #{static.inspect}, setting: #{setting.inspect}, env_var: #{env_var.inspect}, yaml_key: #{yaml_key.inspect})
          end
        RUBY

        if type == :boolean
          alias_method "#{name}?", name
        end
      end
    end

    protected

    def get_setting(name, type: :string, default: nil, static: false, setting: nil, env_var: nil, yaml_key: nil)
      if static
        @static_values ||= {}
        return @static_values[name] if @static_values.include?(name)
      elsif !Rails.application.initialized?
        raise NonStaticValueError.new(self.class, name)
      end

      value = env_value(name, env_var)
      if value.nil? && !static
        value = runtime_value(name, setting)
        if value.nil?
          value = yaml_value(name, yaml_key)
        end
      end
      value = default if value.nil?

      value = coerce_value(value, type).freeze

      @static_vaues[name] = value if static

      value
    end

    private

    def coerce_value(value, type)
      case type
      when :integer
        value&.to_i
      when :float
        value&.to_f
      when :boolean
        SuperSetttings::Coerce.boolean(value)
      when :datetime
        SuperSettings::Coerce.time(value)
      when :array
        Array(value).map(&:to_s)
      else
        value&.to_s
      end
    end

    def env_value(name, env_var)
      return nil if self.class.environment_variables_disabled? || SuperConfig.environment_variables_disabled?

      env_var ||= "#{self.class.env_prefix}#{name.upcase}"
      ENV[env_var]
    end

    def runtime_value(name, setting)
      return nil if self.class.runtime_settings_disabled? || SuperConfig.runtime_settings_disabled?

      setting ||= "#{self.class.setting_prefix}#{name}"
      SuperSettings.get(setting)
    end

    def yaml_value(name, yaml_key)
      return nil if self.class.yaml_file_disabled? || SuperConfig.yaml_file_disabled?

      load_yaml_config

      yaml_key ||= name
      @yaml_config[yaml_key]
    end

    def load_yaml_config
      unless defined?(@yaml_config)
        path = self.class.configuration_file
        @yaml_config = (path.exist? ? Rails.config_for(path) : {})
      end
    end
  end
end
