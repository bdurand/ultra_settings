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

require "super_settings/storage/test_storage"
SuperSettings::Setting.storage = SuperSettings::Storage::TestStorage

require_relative "spec/test_configs/test_configuration"
require_relative "spec/test_configs/other_configuration"
require_relative "spec/test_configs/namespace_configuration"
require_relative "spec/test_configs/subclass_configuration"
require_relative "spec/test_configs/my_service_configuration"

UltraSettings.yaml_config_path = File.join(__dir__, "spec", "config")
UltraSettings.add(:test)
UltraSettings.add(:other)
UltraSettings.add(:namespace, "Test::NamespaceConfiguration")
UltraSettings.add(:my_service, "MyServiceConfiguration")

app = lambda do |env|
  [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
end

run UltraSettings::RackApp.new(app)
