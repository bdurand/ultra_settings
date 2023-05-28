# frozen_string_literal: true

require "super_settings"

require_relative "ultra_settings/components"
require_relative "ultra_settings/configuration"
require_relative "ultra_settings/field"

module UltraSettings
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
      klass = @configurations[name]

      if klass && !Rails.configuration.cache_classes
        klass = nil if klass != class_name.constantize
      end

      unless klass
        klass = class_name.constantize
        @mutex.synchronize do
          unless klass < Configuration
            raise TypeError.new("Configuration class #{class_name} does not inherit from UltraSettings::Configuration")
          end
          @configurations[name] = klass
        end
      end

      klass.instance
    end
  end
end
