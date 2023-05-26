# frozen_string_literal: true

require "bundler/setup"

require "rails"

require_relative "../lib/super_config"

RSpec.configure do |config|
  config.order = :random
end

class TestApplication < Rails::Application
end

Rails.application = TestApplication.new
Rails.application.config.eager_load = false
Rails.env = "test"
Rails.application.initialize!

def Rails.root
  Pathname.new(__dir__)
end

class TestConfiguration < SuperConfig::Configuration
  define :static_value, static: true

  define :foo
  define :bar
  define :baz

  define :int, type: :integer
  define :float, type: :float
  define :bool, type: :boolean
  define :time, type: :datetime
  define :array, type: :array
  define :string, type: :string

  define :default_int, type: :integer, default: "1"
  define :default_bool, type: :boolean, default: "true"
end

class OtherConfiguration < SuperConfig::Configuration
  self.env_prefix = "OTHER_CONFIG_"
  self.setting_prefix = "other_config."
  self.configuration_file = "config/other.yml"

  define :two, type: :integer
  define :three, type: :float
end
