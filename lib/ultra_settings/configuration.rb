# frozen_string_literal: true

module UltraSettings
  class Configuration
    include Singleton

    ALLOWED_NAME_PATTERN = /\A[a-z_][a-zA-Z0-9_]*\z/
    ALLOWED_TYPES = [:string, :symbol, :integer, :float, :boolean, :datetime, :array].freeze

    class << self
      # Define a field on the configuration. This will create a getter method for the field.
      # The field value will be read from the environment, runtime settings, or a YAML file
      # and coerced to the specified type. Empty strings will be converted to nil.
      #
      # @param name [Symbol, String] The name of the field.
      # @param type [Symbol] The type of the field. Valid types are :string, :symbol, :integer,
      #   :float, :boolean, :datetime, and :array. The default type is :string. The :array type
      #   will return an array of strings.
      # @param description [String] A description of the field.
      # @param default [Object] The default value of the field.
      # @param default_if [Proc, Symbol] A proc that returns true if the default value should be used.
      #   By default, the default value will be used if the field evaluates to nil. You can also set
      #   this to a symbol with the name of an instance method to call.
      # @param static [Boolean] If true, the field value should never be changed. This is useful for
      #   fields that are used at startup to set static values in the application. Static field cannot
      #   be read from runtime settings.
      # @param runtime_setting [String, Symbol] The name of the runtime setting to use for the field.
      #   By default this will be the underscored name of the class plus a dot plus the field name
      #   (i.e. MyServiceConfiguration#foo becomes "my_service.foo").
      # @param env_var [String, Symbol] The name of the environment variable to use for the field.
      #   By default this will be the underscored name of the class plus an underscore plus the field name
      #   all in uppercase (i.e. MyServiceConfiguration#foo becomes "MY_SERVICE_FOO").
      # @param yaml_key [String, Symbol] The name of the YAML key to use for the field. By default
      #   this is the name of the field.
      # @return [void]
      def field(name, type: :string, description: nil, default: nil, default_if: nil, static: nil, secret: nil, runtime_setting: nil, env_var: nil, yaml_key: nil)
        name = name.to_s
        type = type.to_sym
        static = !!static
        secret = lambda { fields_secret_by_default? } if secret.nil?

        unless name.match?(ALLOWED_NAME_PATTERN)
          raise ArgumentError.new("Invalid name: #{name.inspect}")
        end

        unless ALLOWED_TYPES.include?(type)
          raise ArgumentError.new("Invalid type: #{type.inspect}")
        end

        unless default_if.nil? || default_if.is_a?(Proc) || default_if.is_a?(Symbol)
          raise ArgumentError.new("default_if must be a Proc or Symbol")
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
          static: static,
          secret: secret
        )

        class_eval <<-RUBY, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            __get_value__(#{name.inspect})
          end
        RUBY

        if type == :boolean
          alias_method :"#{name}?", name
        end
      end

      # List of the defined fields for the configuration.
      #
      # @return [Array<UltraSettings::Field>]
      def fields
        defined_fields.values
      end

      # Check if the field is defined on the configuration.
      #
      # @param name [Symbol, String] The name of the field.
      # @return [Boolean]
      def include?(name)
        name = name.to_s
        return true if defined_fields.include?(name)

        if superclass <= Configuration
          superclass.include?(name)
        else
          false
        end
      end

      # Override the default environment variable prefix. By default this wil be
      # the underscored name of the class plus an underscore
      # (i.e. MyServiceConfiguration has a prefix of "MY_SERVICE_").
      #
      # @param value [String]
      # @return [void]
      def env_var_prefix=(value)
        @env_var_prefix = value&.to_s
      end

      # Get the environment variable prefix.
      #
      # @return [String]
      def env_var_prefix
        unless defined?(@env_var_prefix)
          @env_var_prefix = default_env_var_prefix
        end
        @env_var_prefix
      end

      # Override the default runtime setting prefix. By default this wil be
      # the underscored name of the class plus a dot (i.e. MyServiceConfiguration
      # has a prefix of "my_service.").
      #
      # @param value [String]
      # @return [void]
      def runtime_setting_prefix=(value)
        @runtime_setting_prefix = value&.to_s
      end

      # Get the runtime setting prefix.
      #
      # @return [String]
      def runtime_setting_prefix
        unless defined?(@runtime_setting_prefix)
          @runtime_setting_prefix = default_runtime_setting_prefix
        end
        @runtime_setting_prefix
      end

      # Override the default YAML config path. By default this will be the
      # file matching the underscored name of the class in the configuration
      # directory (i.e. MyServiceConfiguration has a default config path of
      # "my_service.yml").
      #
      # @param value [String, Pathname]
      # @return [void]
      def configuration_file=(value)
        value = Pathname.new(value) if value.is_a?(String)
        @configuration_file = value
      end

      # Get the YAML file path.
      #
      # @return [Pathname, nil]
      def configuration_file
        unless defined?(@configuration_file)
          @configuration_file = default_configuration_file
        end
        return nil? unless @configuration_file

        path = @configuration_file
        if path.relative? && yaml_config_path
          path = yaml_config_path.join(path)
        end
        path.expand_path
      end

      # Set to true to disable loading configuration from environment variables.
      #
      # @param value [Boolean]
      # @return [void]
      def environment_variables_disabled=(value)
        set_inheritable_class_attribute(:@environment_variables_disabled, !!value)
      end

      # Check if loading configuration from environment variables is disabled.
      #
      # @return [Boolean]
      def environment_variables_disabled?
        get_inheritable_class_attribute(:@environment_variables_disabled, false)
      end

      # Set to true to disable loading configuration from runtime settings.
      #
      # @param value [Boolean]
      # @return [void]
      def runtime_settings_disabled=(value)
        set_inheritable_class_attribute(:@runtime_settings_disabled, !!value)
      end

      # Check if loading configuration from runtime settings is disabled.
      #
      # @return [Boolean]
      def runtime_settings_disabled?
        get_inheritable_class_attribute(:@runtime_settings_disabled, false)
      end

      # Set to true to disable loading configuration from YAML files.
      #
      # @param value [Boolean]
      # @return [void]
      def yaml_config_disabled=(value)
        set_inheritable_class_attribute(:@yaml_config_disabled, !!value)
      end

      # Check if loading configuration from YAML files is disabled.
      #
      # @return [Boolean]
      def yaml_config_disabled?
        get_inheritable_class_attribute(:@yaml_config_disabled, false)
      end

      # Set the environment variable delimiter used to construct the environment
      # variable name for a field. By default this is an underscore.
      #
      # @param value [String]
      def env_var_delimiter=(value)
        set_inheritable_class_attribute(:@env_var_delimiter, value.to_s)
      end

      # Get the environment variable delimiter.
      #
      # @return [String]
      def env_var_delimiter
        get_inheritable_class_attribute(:@env_var_delimiter, "_")
      end

      # Set the runtime setting delimiter used to construct the runtime setting
      # name for a field. By default this is a dot.
      #
      # @param value [String]
      # @return [void]
      def runtime_setting_delimiter=(value)
        set_inheritable_class_attribute(:@runtime_setting_delimiter, value.to_s)
      end

      # Get the runtime setting delimiter.
      #
      # @return [String]
      def runtime_setting_delimiter
        get_inheritable_class_attribute(:@runtime_setting_delimiter, ".")
      end

      # Set to true to upcase the environment variable name for a field. This
      # is true by default.
      #
      # @param value [Boolean]
      # @return [void]
      def env_var_upcase=(value)
        set_inheritable_class_attribute(:@env_var_upcase, !!value)
      end

      # Check if the environment variable name for a field should be upcased.
      #
      # @return [Boolean]
      def env_var_upcase?
        get_inheritable_class_attribute(:@env_var_upcase, true)
      end

      # Set to true to upcase the runtime setting name for a field. This
      # is false by default.
      #
      # @param value [Boolean]
      # @return [void]
      def runtime_setting_upcase=(value)
        set_inheritable_class_attribute(:@runtime_setting_upcase, !!value)
      end

      # Check if the runtime setting name for a field should be upcased.
      #
      # @return [Boolean]
      def runtime_setting_upcase?
        get_inheritable_class_attribute(:@runtime_setting_upcase, false)
      end

      # Set the directory where YAML files will be loaded from. By default this
      # is the current working directory.
      #
      # @param value [String, Pathname]
      # @return [void]
      def yaml_config_path=(value)
        value = Pathname.new(value) if value.is_a?(String)
        value = value.expand_path if value&.relative?
        set_inheritable_class_attribute(:@yaml_config_path, value)
      end

      # Get the directory where YAML files will be loaded from.
      #
      # @return [Pathname, nil]
      def yaml_config_path
        get_inheritable_class_attribute(:@yaml_config_path, nil)
      end

      # Set the environment namespace used in YAML file name. By default this
      # is "development". Settings from the specific environment hash in the YAML
      # file will be merged with base settings specified in the "shared" hash.
      #
      # @param value [String]
      # @return [void]
      def yaml_config_env=(value)
        set_inheritable_class_attribute(:@yaml_config_env, value)
      end

      # Get the environment namespace used in YAML file name.
      #
      # @return [String]
      def yaml_config_env
        get_inheritable_class_attribute(:@yaml_config_env, "development")
      end

      # Sets the default value for the secret property of fields. Individual fields can still
      # override this value by explicitly setting the secret property. By default, fields are
      # considered secret.
      #
      # @param value [Boolean]
      # @return [void]
      def fields_secret_by_default=(value)
        set_inheritable_class_attribute(:@fields_secret_by_default, !!value)
      end

      # Check if fields are considered secret by default.
      #
      # @return [Boolean]
      def fields_secret_by_default?
        get_inheritable_class_attribute(:@fields_secret_by_default, true)
      end

      # Override field values within a block.
      #
      # @param values [Hash<Symbol, Object>]] List of fields with the values they
      #   should return within the block.
      # @return [Object] The value returned by the block.
      def override!(values, &block)
        instance.override!(values, &block)
      end

      # Load the YAML file for this configuration and return the values for the
      # current environment.
      #
      # @return [Hash]
      def load_yaml_config
        return nil unless configuration_file
        return nil unless configuration_file.exist? && configuration_file.file?

        YamlConfig.new(configuration_file, yaml_config_env).to_h
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
        name.sub(/Configuration\z/, "").split("::").collect do |part|
          part.gsub(/([A-Z])(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { ($1 || $2) << "_" }.downcase
        end.join("/")
      end

      def set_inheritable_class_attribute(name, value)
        instance_variable_set(name, value)
      end

      def get_inheritable_class_attribute(name, default = nil)
        if instance_variable_defined?(name)
          instance_variable_get(name)
        elsif self != Configuration
          superclass.send(:get_inheritable_class_attribute, name, default)
        else
          default
        end
      end

      def default_configuration_file
        path = Pathname.new(yaml_config_path)
        path.join(*"#{root_name}.yml".split("/"))
      end

      def default_env_var_prefix
        prefix = root_name.gsub("/", env_var_delimiter) + env_var_delimiter
        prefix = prefix.upcase if env_var_upcase?
        prefix
      end

      def default_runtime_setting_prefix
        prefix = root_name.gsub("/", runtime_setting_delimiter) + runtime_setting_delimiter
        prefix = prefix.upcase if runtime_setting_upcase?
        prefix
      end

      def construct_env_var(name, env_var)
        return nil if env_var == false
        return nil if environment_variables_disabled? && env_var.nil?

        env_var = nil if env_var == true

        if env_var.nil?
          env_var = "#{env_var_prefix}#{name}"
          env_var = env_var.upcase if env_var_upcase?
        end

        env_var
      end

      def construct_runtime_setting(name, runtime_setting)
        return nil if runtime_setting == false
        return nil if runtime_settings_disabled? && runtime_setting.nil?

        runtime_setting = nil if runtime_setting == true

        if runtime_setting.nil?
          runtime_setting = "#{runtime_setting_prefix}#{name}"
          runtime_setting = runtime_setting.upcase if runtime_setting_upcase?
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
      @override_values = {}
      @yaml_config = nil
    end

    def [](name)
      send(name.to_s) if include?(name)
    end

    def include?(name)
      self.class.include?(name.to_s)
    end

    def override!(values, &block)
      save_val = @override_values[Thread.current.object_id]

      temp_values = (save_val || {}).dup
      values.each do |key, value|
        temp_values[key.to_s] = value
      end

      begin
        @mutex.synchronize do
          @override_values[Thread.current.object_id] = temp_values
        end
        yield
      ensure
        @mutex.synchronize do
          @override_values[Thread.current.object_id] = save_val
        end
      end
    end

    # Get the current source for the field.
    #
    # @param name [String, Symbol] the name of the field.
    # @return [Symbol, nil] The source of the value (:env, :settings, :yaml, or :default).
    def __source__(name)
      field = self.class.send(:defined_fields)[name.to_s]
      raise ArgumentError.new("Unknown field: #{name.inspect}") unless field

      source = field.source(env: ENV, settings: UltraSettings.__runtime_settings__, yaml_config: __yaml_config__)
      source || :default
    end

    # Get the value of the field from the specified source.
    #
    # @param name [String, Symbol] the name of the field.
    # @param source [Symbol] the source of the value (:env, :settings, :yaml, or :default).
    # @return [Object] The value of the field.
    def __value_from_source__(name, source)
      field = self.class.send(:defined_fields)[name.to_s]
      raise ArgumentError.new("Unknown field: #{name.inspect}") unless field

      case source
      when :env
        field.value(env: ENV)
      when :settings
        field.value(settings: UltraSettings.__runtime_settings__)
      when :yaml
        field.value(yaml_config: __yaml_config__)
      when :default
        field.default
      else
        raise ArgumentError.new("Unknown source: #{source.inspect}")
      end
    end

    # Output the current state of the configuration as a hash. If the field is marked as a secret,
    # then the value will be a secure hash of the value instead of the value itself.
    #
    # The intent of this method is to provide a serializable value that captures the current state
    # of the configuration without exposing any secrets. You could, for instance, use the output
    # to compare the configuration of you application between two different environments.
    #
    # @return [Hash]
    def _to_h
      payload = {}
      self.class.fields.each do |field|
        value = self[field.name]
        if field.secret? && !value.nil?
          value = "securehash:#{Digest::MD5.hexdigest(Digest::SHA256.hexdigest(value.to_s))}"
        end
        payload[field.name] = value
      end
      payload
    end

    private

    def __get_value__(name)
      field = self.class.send(:defined_fields)[name]
      return nil unless field

      if field.static? && @memoized_values.include?(name)
        return @memoized_values[name]
      end

      if @override_values[Thread.current.object_id]&.include?(name)
        value = field.coerce(@override_values[Thread.current.object_id][name])
      else
        env = ENV if field.env_var
        settings = UltraSettings.__runtime_settings__ if field.runtime_setting
        yaml_config = __yaml_config__ if field.yaml_key

        value = field.value(yaml_config: yaml_config, env: env, settings: settings)
      end

      if __use_default?(value, field.default_if)
        value = field.default
      end

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

    def __use_default?(value, default_if)
      return true if value.nil?

      if default_if.is_a?(Proc)
        default_if.call(value)
      elsif default_if.is_a?(Symbol)
        begin
          send(default_if, value)
        rescue NoMethodError
          raise NoMethodError, "default_if method `#{default_if}' not defined for #{self.class.name}"
        end
      else
        false
      end
    end

    def __yaml_config__
      @yaml_config ||= self.class.load_yaml_config || {}
    end
  end
end
