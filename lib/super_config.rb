# frozen_string_literal: true

require "super_settings"

require_relative "super_config/configuration"
require_relative "super_config/field"

module SuperConfig
  @configurations = {}
  @mutex = Mutex.new

  class NonStaticValueError < StandardError
  end

  class << self
    def add(name, klass = nil)
      name = name.to_s
      unless name.match?(/\A[a-z_][a-zA-Z0-9_]*\z/)
        raise ArgementError.new("Invalid configuration name: #{name.inspect}")
      end

      class_name = klass&.to_s
      class_name ||= "#{name.classify}Configuration"

      @mutex.synchronize do
        @configurations.delete(name)

        eval <<-RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            __load_config__(#{name.inspect}, #{class_name.inspect})
          end
        RUBY
      end
    end

    def disable_environment_variables!
      @environment_variables_disabled = true
    end

    def environment_variables_disabled?
      !!(defined?(@environment_variables_disabled) && @environment_variables_disabled)
    end

    def disable_runtime_settings!
      @runtime_settings_disabled = true
    end

    def runtime_settings_disabled?
      !!(defined?(@runtime_settings_disabled) && @runtime_settings_disabled)
    end

    def disable_yaml_config!
      @yaml_config_disabled = true
    end

    def yaml_config_disabled?
      !!(defined?(@yaml_config_disabled) && @yaml_config_disabled)
    end

    private

    def __load_config__(name, class_name)
      config = @configurations[name]

      if config && !Rails.configuration.cache_classes
        config = nil if config.class != class_name.constantize
      end

      unless config
        klass = class_name.constantize
        @mutex.synchronize do
          config = klass.new
          unless config.is_a?(Configuration)
            raise TypeError.new("Configuration class #{class_name} does not inherit from SuperConfig::Configuration")
          end
          @configurations[name] = config
        end
      end
      config
    end
  end
end
