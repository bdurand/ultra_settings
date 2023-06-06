# frozen_string_literal: true

require "singleton"

module UltraSettings
  class Configuration
    include Singleton

    ALLOWED_NAME_PATTERN = /\A[a-z_][a-zA-Z0-9_]*\z/
    ALLOWED_TYPES = [:string, :symbol, :integer, :float, :boolean, :datetime, :array].freeze

    class_attribute :environment_variables_disabled, instance_accessor: false, default: false

    class_attribute :runtime_settings_disabled, instance_accessor: false, default: false

    class_attribute :yaml_config_disabled, instance_accessor: false, default: false

    class_attribute :env_var_delimiter, instance_accessor: false, default: "_"

    class_attribute :runtime_setting_delimiter, instance_accessor: false, default: "."

    class_attribute :env_var_upcase, instance_accessor: false, default: true

    class_attribute :runtime_setting_upcase, instance_accessor: false, default: false

    class_attribute :yaml_config_directory, instance_accessor: false, default: "config"

    class << self
      def field(name, type: :string, description: nil, default: nil, default_if: nil, static: false, runtime_setting: nil, env_var: nil, yaml_key: nil)
        name = name.to_s
        type = type.to_sym
        static = !!static

        unless name.match?(ALLOWED_NAME_PATTERN)
          raise ArgumentError.new("Invalid name: #{name.inspect}")
        end

        unless ALLOWED_TYPES.include?(type)
          raise ArgumentError.new("Invalid type: #{type.inspect}")
        end

        unless default_if.nil? || default_if.is_a?(Proc)
          raise ArgumentError.new("default_if must be a Proc")
        end

        defined_fields[name] = Field.new(
          name: name,
          type: type,
          description: description,
          default: default,
          default_if: default_if,
          env_var: construct_env_var(name, env_var),
          runtime_setting: (static ? nil : construct_runtime_setting(name, runtime_setting)),
          yaml_key: construct_yaml_key(name, yaml_key),
          static: static
        )

        class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            __get_value__(#{name.inspect})
          end
        RUBY

        if type == :boolean
          alias_method "#{name}?", name
        end
      end

      def fields
        defined_fields.values
      end

      def include?(name)
        name = name.to_s
        return true if defined_fields.include?(name)

        if superclass <= Configuration
          superclass.include?(name)
        else
          false
        end
      end

      def env_var_prefix=(value)
        @env_var_prefix = value&.to_s
      end

      def env_var_prefix
        unless defined?(@env_var_prefix)
          @env_var_prefix = default_env_var_prefix
        end
        @env_var_prefix
      end

      def runtime_setting_prefix=(value)
        @runtime_setting_prefix = value&.to_s
      end

      def runtime_setting_prefix
        unless defined?(@runtime_setting_prefix)
          @runtime_setting_prefix = default_runtime_setting_prefix
        end
        @runtime_setting_prefix
      end

      def configuration_file=(value)
        value = Pathname.new(value) if value.is_a?(String)
        value = Rails.root + value if value && !value.absolute? && Rails.root
        @configuration_file = value
      end

      def configuration_file
        unless defined?(@configuration_file)
          @configuration_file = default_configuration_file
        end
        @configuration_file
      end

      def load_yaml_config
        return nil unless configuration_file
        return nil unless configuration_file.exist?

        Rails.application.config_for(configuration_file)
      end

      private

      def defined_fields
        unless defined?(@defined_fields)
          fields = {}
          if superclass <= Configuration
            fields = superclass.send(:defined_fields).dup
          end
          @defined_fields = fields
        end
        @defined_fields
      end

      def root_name
        name.sub(/Configuration\z/, "")
      end

      def default_configuration_file
        path = Pathname.new(yaml_config_directory)
        path = Rails.root + path if defined?(Rails) && !path.absolute?
        path.join(*"#{root_name.underscore}.yml".split("/"))
      end

      def default_env_var_prefix
        prefix = root_name.underscore.gsub("/", env_var_delimiter) + env_var_delimiter
        prefix = prefix.upcase if env_var_upcase
        prefix
      end

      def default_runtime_setting_prefix
        prefix = root_name.underscore.gsub("/", runtime_setting_delimiter) + runtime_setting_delimiter
        prefix = prefix.upcase if runtime_setting_upcase
        prefix
      end

      def construct_env_var(name, env_var)
        return nil if env_var == false
        return nil if environment_variables_disabled? && env_var.nil?

        env_var = nil if env_var == true
        if env_var.nil?
          env_var = "#{env_var_prefix}#{name}"
          env_var = env_var.upcase if env_var_upcase
        end

        env_var
      end

      def construct_runtime_setting(name, runtime_setting)
        return nil if runtime_setting == false
        return nil if runtime_settings_disabled? && runtime_setting.nil?

        runtime_setting = nil if runtime_setting == true
        if runtime_setting.nil?
          runtime_setting = "#{runtime_setting_prefix}#{name}"
          runtime_setting = runtime_setting.upcase if runtime_setting_upcase
        end

        runtime_setting
      end

      def construct_yaml_key(name, yaml_key)
        return nil if yaml_key == false
        return nil if yaml_config_disabled? && yaml_key.nil?

        yaml_key = nil if yaml_key == true
        yaml_key = name if yaml_key.nil?

        yaml_key
      end
    end

    def initialize
      @mutex = Mutex.new
      @memoized_values = {}
    end

    def [](name)
      send(name.to_s) if include?(name)
    end

    def include?(name)
      self.class.include?(name.to_s)
    end

    def __source__(name)
      field = self.class.send(:defined_fields)[name]
      field.source(env: ENV, settings: __runtime_settings__, yaml_config: __yaml_config__)
    end

    private

    def __get_value__(name)
      field = self.class.send(:defined_fields)[name]
      return nil unless field

      if field.static? && @memoized_values.include?(name)
        return @memoized_values[name]
      end

      if !Rails.application.initialized? && !field.static?
        raise UltraSettings::NonStaticValueError.new("Cannot access non-static field #{name} during initialization")
      end

      env = ENV if field.env_var
      settings = __runtime_settings__ if field.runtime_setting
      yaml_config = __yaml_config__ if field.yaml_key

      value = field.value(yaml_config: yaml_config, env: env, settings: settings)

      if field.static?
        @mutex.synchronize do
          if @memoized_values.include?(name)
            value = @memoized_values[name]
          else
            @memoized_values[name] = value
          end
        end
      end

      value
    end

    def __runtime_settings__
      SuperSettings
    end

    def __yaml_config__
      @yaml_config ||= (self.class.load_yaml_config || {})
    end
  end
end
