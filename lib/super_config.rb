# frozen_string_literal: true

require_relative "super_config/components"
require_relative "super_config/configuration"
require_relative "super_config/non_static_value_error"

module SuperConfig
  @configurations = {}
  @configuration_classes = {}
  @mutex = Mutex.new

  extend Components

  class << self
    def add(name, klass = nil)
      name = name.to_s
      unless name.match?(/\A[a-z_][a-zA-Z0-9_]*\z/)
        raise ArgementError.new("Invalid configuration name: #{name.inspect}")
      end

      class_name = klass&.to_s
      class_name ||= "#{name.classify}Configuration"

      @mutex.synchronize do
        @configuration_classes[name] = class_name
        @configurations.delete(name)

        eval <<-RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
          def #{name}
            config = @configurations[#{name.inspect}]
            unless config
              config = #{class_name}.new
              unless config.is_a?(Configuration)
                raise TypeError.new("Configuration class #{class_name} does not inherit from SuperConfig::Configuration")
              end
              @configurations[#{name.inspect}] = config
            end
            config
          end
        RUBY
      end
    end
  end
end
