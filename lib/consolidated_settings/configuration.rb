# frozen_string_literal: true

module ConsolidatedSettings
  class Configuration
    extend Components

    ALLOWED_NAME_PATTERN = /\A[a-z_][a-zA-Z0-9_]*\z/
    ALLOWED_TYPES = [:string, :integer, :float, :boolean, :datetime, :array].freeze

    class_attribute :environment_variables_disabled, instance_accessor: false, default: false

    class_attribute :runtime_settings_disabled, instance_accessor: false, default: false

    class_attribute :yaml_config_disabled, instance_accessor: false, default: false

    class << self
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

        defined_fields[name] = Field.new(
          name: name,
          type: type,
          default: default,
          env_var: env_var,
          setting_name: setting,
          yaml_key: yaml_key,
          env_var_prefix: env_var_prefix,
          setting_prefix: setting_prefix
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
          @defined_fields = {}
          if superclass < Configuration
            superclass.send(:defined_fields).each do |name, field|
              @defined_fields[name] = Field.new(
                name: field.name,
                type: field.type,
                default: field.default,
                env_var: field.env_var,
                setting_name: field.setting_name,
                yaml_key: field.yaml_key,
                env_var_prefix: env_var_prefix,
                setting_prefix: setting_prefix
              )
            end
          end
        end
        @defined_fields
      end

      def root_name
        name.sub(/Configuration\z/, "")
      end

      def default_configuration_file
        (Rails.root + "config").join(*"#{root_name.underscore}.yml".split("/"))
      end

      def default_env_var_prefix
        root_name.underscore.tr("/", "_").upcase + "_"
      end

      def default_setting_prefix
        root_name.underscore.tr("/", ".") + "."
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
      self.class.send(:defined_fields).include?(name.to_s)
    end

    private

    def __get_value__(name, static)
      if static && @memoized_values.include?(name)
        return @memoized_values[name]
      end

      field = self.class.send(:defined_fields)[name]
      return nil unless field

      if !Rails.application.initialized? && !static
        raise ConsolidatedSettings::NonStaticValueError.new("Cannot access non-static field #{name} during initialization")
      end

      env = ENV unless self.class.environment_variables_disabled? || ConsolidatedSettings.environment_variables_disabled?
      settings = SuperSettings unless static || self.class.runtime_settings_disabled? || ConsolidatedSettings.runtime_settings_disabled?
      yaml_config = __yaml_config__ unless self.class.yaml_config_disabled? || ConsolidatedSettings.yaml_config_disabled?

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

    def __yaml_config__
      @yaml_config ||= (self.class.load_yaml_config || {})
    end
  end
end
