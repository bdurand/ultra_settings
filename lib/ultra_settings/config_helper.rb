# frozen_string_literal: true

module UltraSettings
  # Helper module for setting up a class to use the config methods
  #
  # Usage:
  # class TestClass
  #   extend UltraSettings::ConfigHelper
  #   configuration_class TestConfiguration
  # end
  # TestClass.config => TestConfiguration.instance
  # TestClass.new.config => TestConfiguration.instance
  module ConfigHelper
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
