# frozen_string_literal: true

require "bundler/setup"

require "climate_control"
require "nokogiri"

require_relative "../lib/ultra_settings"

UltraSettings.yaml_config_path = Pathname.new(__dir__) + "config"
UltraSettings.yaml_config_env = "test"

UltraSettings.add(:test)
UltraSettings.add(:test2, "OtherConfiguration")

require_relative "test_configs/test_configuration"
require_relative "test_configs/other_configuration"
require_relative "test_configs/namespace_configuration"
require_relative "test_configs/subclass_configuration"
require_relative "test_configs/disabled_sources_configuration"
require_relative "test_configs/my_service_configuration"
require_relative "test_configs/explicit_configuration"

class TestRuntimeSetings
  def initialize(hash = {})
    @settings = {}
    hash.each do |key, value|
      @settings[key.to_s] = value
    end
  end

  def [](name)
    @settings[name]
  end
end

RSpec.configure do |config|
  config.warnings = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.around do |example|
    if example.metadata[:env].is_a?(Hash)
      ClimateControl.modify(example.metadata[:env]) do
        example.run
      end
    else
      example.run
    end
  end

  config.around do |example|
    if example.metadata[:settings].is_a?(Hash)
      settings = TestRuntimeSetings.new(example.metadata[:settings])
      begin
        UltraSettings.runtime_settings = settings
        example.run
      ensure
        UltraSettings.runtime_settings = nil
      end
    else
      example.run
    end
  end

  config.around do |example|
    if example.metadata[:ultra_settings].is_a?(Hash)
      UltraSettings.override!(example.metadata[:ultra_settings]) do
        example.run
      end
    else
      example.run
    end
  end
end
