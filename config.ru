# This is a sample rackup file for testing the UltraSettings web UI.
#
# ```bash
# bundle exec rackup
# ```
#
# Then visit http://localhost:9292/

require "bundler/setup"

Bundler.setup(:default)

require_relative "lib/ultra_settings"

if ENV.fetch("USE_SUPER_SETTINGS", "true") == "true"
  require "super_settings"
  require "super_settings/storage/test_storage"
  SuperSettings::Setting.storage = SuperSettings::Storage::TestStorage
  UltraSettings.super_settings_editing = lambda { |req| ENV.fetch("SUPER_SETTINGS_EDITING", "true") == "true" }
else
  UltraSettings.runtime_settings = {"my_service.timeout" => 2.5}
end

UltraSettings.fields_secret_by_default = false
UltraSettings.yaml_config_path = File.join(__dir__, "spec", "config")
UltraSettings.runtime_settings_url = ENV.fetch("RUNTIME_SETTINGS_URL", "http://localhost:9494#edit=${name}&type=${type}&description=${description}")

require_relative "spec/test_configs/test_configuration"
require_relative "spec/test_configs/other_configuration"
require_relative "spec/test_configs/namespace_configuration"
require_relative "spec/test_configs/subclass_configuration"
require_relative "spec/test_configs/my_service_configuration"

# This configuration is not valid and should not appear in the UI.
class BlankConfiguration < UltraSettings::Configuration
end

ENV.fetch("TEST_CONFIG_COUNT", "0").to_i.times do |i|
  klass = Class.new(TestConfiguration)
  Object.const_set("TestConfiguration#{i}", klass)
end

UltraSettings.add(:test)
UltraSettings.add(:namespace, "Test::NamespaceConfiguration")

run UltraSettings::RackApp.new(color_scheme: ENV.fetch("COLOR_SCHEME", nil))
