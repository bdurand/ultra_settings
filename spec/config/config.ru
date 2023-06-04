require "bundler/setup"

Bundler.setup(:default)

require "rails"
require_relative "../../lib/ultra_settings"

Rails.application = Class.new(Rails::Application)

require "super_settings/storage/test_storage"
SuperSettings::Setting.storage = SuperSettings::Storage::TestStorage

require_relative "../test_configs/test_configuration"
require_relative "../test_configs/other_configuration"
require_relative "../test_configs/namespace_configuration"
require_relative "../test_configs/subclass_configuration"

UltraSettings.yaml_config_directory = __dir__
UltraSettings.add(:test)
UltraSettings.add(:other)
UltraSettings.add(:subclass)
UltraSettings.add(:namespace, "Test::NamespaceConfiguration")

app = lambda do |env|
  [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
end

run UltraSettings::RackApp.new(app)
