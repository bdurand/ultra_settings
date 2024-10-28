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

require_relative "spec/test_configs/test_configuration"
require_relative "spec/test_configs/other_configuration"
require_relative "spec/test_configs/namespace_configuration"
require_relative "spec/test_configs/subclass_configuration"
require_relative "spec/test_configs/my_service_configuration"

UltraSettings.fields_secret_by_default = false
UltraSettings.yaml_config_path = File.join(__dir__, "spec", "config")
UltraSettings.runtime_settings = {"my_service.timeout" => 2.5}
UltraSettings.runtime_settings_url = ENV.fetch("RUNTIME_SETTINGS_URL", "http://localhost:9494#edit=${name}")
UltraSettings.add(:test)
UltraSettings.add(:other)
UltraSettings.add(:namespace, "Test::NamespaceConfiguration")
UltraSettings.add(:my_service, "MyServiceConfiguration")

run UltraSettings::RackApp.new(color_scheme: ENV.fetch("COLOR_SCHEME", nil))
