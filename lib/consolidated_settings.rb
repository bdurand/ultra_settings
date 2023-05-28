# frozen_string_literal: true

require "super_settings"

require_relative "consolidated_settings/components"
require_relative "consolidated_settings/configuration"
require_relative "consolidated_settings/field"

module ConsolidatedSettings
  @configurations = {}
  @mutex = Mutex.new

  extend Components

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
            raise TypeError.new("Configuration class #{class_name} does not inherit from ConsolidatedSettings::Configuration")
          end
          @configurations[name] = config
        end
      end
      config
    end
  end
end
