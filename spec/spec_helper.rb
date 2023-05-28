# frozen_string_literal: true

require "bundler/setup"

require "rails"
require "climate_control"

require_relative "../lib/consolidated_settings"

require "super_settings/storage/test_storage"
SuperSettings::Setting.storage = SuperSettings::Storage::TestStorage

class TestApplication < Rails::Application
end

Rails.application = TestApplication.new
Rails.application.config.eager_load = false
Rails.env = "test"
Rails.logger = Logger.new(File::NULL)
Rails.application.initialize!

def Rails.root
  Pathname.new(__dir__)
end

ConsolidatedSettings.add(:test)
ConsolidatedSettings.add(:test2, "OtherConfiguration")

require_relative "test_configs/test_configuration"
require_relative "test_configs/other_configuration"
require_relative "test_configs/subclass_configuration"

RSpec.configure do |config|
  config.order = :random

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
    SuperSettings::Storage::TestStorage.clear
    SuperSettings.clear_cache

    if example.metadata[:settings].is_a?(Hash)
      previous = {}
      begin
        example.metadata[:settings].each do |name, value|
          previous[name] = value
          SuperSettings.set(name, value)
        end
        example.run
      ensure
        previous.each do |name, value|
          SuperSettings.set(name, value)
        end
      end
    else
      example.run
    end
  end
end
