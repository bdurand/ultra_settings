# frozen_string_literal: true

module UltraSettings
  # Helper module for setting up a class to use the config methods.
  #
  # @example
  #   class TestClass
  #     extend UltraSettings::ConfigHelper
  #     configuration_class TestConfiguration
  #   end
  #   TestClass.config # => TestConfiguration.instance
  #   TestClass.new.config # => TestConfiguration.instance
  module ConfigHelper
    # Define the configuration class and create config methods.
    #
    # @param config_class [Class] The configuration class to use.
    # @return [void]
    def configuration_class(config_class)
      define_singleton_method :config do
        config_class.instance
      end

      define_method :config do
        self.class.config
      end
    end
  end
end
