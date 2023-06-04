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

    class_attribute :setting_delimiter, instance_accessor: false, default: "."

    class_attribute :env_var_upcase, instance_accessor: false, default: true

    class_attribute :setting_upcase, instance_accessor: false, default: false

    class_attribute :yaml_config_directory, instance_accessor: false, default: "config"

    class << self
      def define(name, type: :string, description: nil, default: nil, default_if: nil, static: false, setting: nil, env_var: nil, yaml_key: nil)
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
          setting_name: construct_setting_name(name, setting),
          yaml_key: construct_yaml_key(name, yaml_key)
        )

        class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            __get_value__(#{name.inspect}, #{static.inspect})
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

      def setting_prefix=(value)
        @setting_prefix = value&.to_s
      end

      def setting_prefix
        unless defined?(@setting_prefix)
          @setting_prefix = default_setting_prefix
        end
        @setting_prefix
      end

      def configuration_file=(value)
        value = Pathname.new(value) if value.is_a?(String)
        value = Rails.root + value if value && !value.absolute?
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

      def default_setting_prefix
        prefix = root_name.underscore.gsub("/", setting_delimiter) + setting_delimiter
        prefix = prefix.upcase if setting_upcase
        prefix
      end

      def construct_env_var(name, env_var)
        return nil if env_var == false

        env_var = nil if env_var == true
        if env_var.nil?
          env_var = "#{env_var_prefix}#{name}"
          env_var = env_var.upcase if env_var_upcase
        end

        env_var
      end

      def construct_setting_name(name, setting_name)
        return nil if setting_name == false

        setting_name = nil if setting_name == true
        if setting_name.nil?
          setting_name = "#{setting_prefix}#{name}"
          setting_name = setting_name.upcase if setting_upcase
        end

        setting_name
      end

      def construct_yaml_key(name, yaml_key)
        return nil if yaml_key == false

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

    private

    def __get_value__(name, static)
      if static && @memoized_values.include?(name)
        return @memoized_values[name]
      end

      field = self.class.send(:defined_fields)[name]
      return nil unless field

      if !Rails.application.initialized? && !static
        raise UltraSettings::NonStaticValueError.new("Cannot access non-static field #{name} during initialization")
      end

      env = ENV unless self.class.environment_variables_disabled?
      settings = __runtime_settings__ unless static || self.class.runtime_settings_disabled?
      yaml_config = __yaml_config__ unless self.class.yaml_config_disabled?

      value = field.value(yaml_config: yaml_config, env: env, settings: settings)

      if static
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
