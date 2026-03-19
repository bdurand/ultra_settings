# This is a sample rackup file for testing the UltraSettings web UI.
#
# It demonstrates three ways to use the web UI:
#
# 1. Stand-alone Rack app   — GET /
# 2. Embedded ApplicationView — GET /embedded
# 3. Embedded ConfigurationView — GET /test_configuration
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
  UltraSettings.super_settings_api_path = "/super_settings"
else
  UltraSettings.runtime_settings = {"my_service.timeout" => 2.5}
end

UltraSettings.fields_secret_by_default = false
UltraSettings.runtime_settings_secure = false
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

# Helper class for rendering embedded views inside a sample application layout.
# This demonstrates how you would embed the UltraSettings views in your own
# application pages with your own header, sidebars, and footer.
class SampleEmbeddedApp
  LAYOUT_TEMPLATE = File.join(__dir__, "test_app", "app", "views", "layout.html.erb")

  def initialize(color_scheme: nil)
    @color_scheme = color_scheme&.to_sym
  end

  def call(env)
    content = yield
    title = env["ultra_settings.title"] || "Settings"
    color_scheme = @color_scheme
    html = render_layout(title: title, content: content, color_scheme: color_scheme)
    [200, {"content-type" => "text/html; charset=utf-8"}, [html]]
  end

  private

  def render_layout(title:, content:, color_scheme:)
    ERB.new(File.read(LAYOUT_TEMPLATE)).result(binding)
  end
end

color_scheme = ENV.fetch("COLOR_SCHEME", nil)
embedded_app = SampleEmbeddedApp.new(color_scheme: color_scheme)

# GET /embedded — Demonstrates embedding UltraSettings::ApplicationView
# in your own application layout with a header, sidebar, and footer.
embedded_application = lambda do |env|
  env["ultra_settings.title"] = "Embedded Settings"
  embedded_app.call(env) do
    <<~HTML
      <h2>Application Settings</h2>
      <p class="subtitle">
        This page demonstrates embedding <code>UltraSettings::ApplicationView</code>
        inside your own application layout.
      </p>
      #{UltraSettings::ApplicationView.new(color_scheme: color_scheme&.to_sym).render}
    HTML
  end
end

# GET /test_configuration — Demonstrates embedding UltraSettings::ConfigurationView
# for a single configuration in your own application layout.
embedded_configuration = lambda do |env|
  env["ultra_settings.title"] = "Test Configuration"
  embedded_app.call(env) do
    <<~HTML
      <h2>Test Configuration</h2>
      <p class="subtitle">
        This page demonstrates embedding <code>UltraSettings::ConfigurationView</code>
        for a single configuration inside your own application layout.
      </p>
      #{UltraSettings::ConfigurationView.new(TestConfiguration.instance).render}
    HTML
  end
end

ultra_settings_app = Rack::URLMap.new(
  "/" => UltraSettings::RackApp.new(color_scheme: color_scheme),
  "/embedded" => embedded_application,
  "/test_configuration" => embedded_configuration
)

if defined?(SuperSettings::RackApplication)
  # Mount SuperSettings as middleware with a path prefix.
  # Requests to /super_settings/* are handled by SuperSettings;
  # all others fall through to the UltraSettings app.
  app = SuperSettings::RackApplication.new(ultra_settings_app, "/super_settings") do
    def current_user(request)
      "demo"
    end
  end
  run app
else
  run ultra_settings_app
end
