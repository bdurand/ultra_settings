# frozen_string_literal: true

require "spec_helper"

# Runtime settings implementation that supports being reloaded, like SuperSettings does.
class ReloadableRuntimeSettings
  attr_reader :load_count

  def initialize(hash = {}, error: nil)
    @settings = {}
    hash.each do |key, value|
      @settings[key.to_s] = value
    end
    @load_count = 0
    @error = error
  end

  def [](name)
    @settings[name]
  end

  def load_settings
    @load_count += 1
    raise @error if @error
    nil
  end
end

RSpec.describe "reloading runtime settings in the web views" do
  let(:runtime_settings) { ReloadableRuntimeSettings.new({"my_service.timeout" => 2.5}) }

  around do |example|
    save_val = UltraSettings.__runtime_settings__
    begin
      UltraSettings.runtime_settings = runtime_settings
      example.run
    ensure
      UltraSettings.runtime_settings = save_val
    end
  end

  it "reloads the runtime settings when rendering a single configuration" do
    UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    expect(runtime_settings.load_count).to eq 1
  end

  it "reloads the runtime settings only once when rendering all configurations" do
    expect(UltraSettings.__configurations__.size).to be > 1

    UltraSettings::ApplicationView.new.render
    expect(runtime_settings.load_count).to eq 1
  end

  it "reloads the runtime settings only once when rendering the full page" do
    UltraSettings::WebView.new.render_settings
    expect(runtime_settings.load_count).to eq 1
  end

  it "reloads on every render rather than only the first one" do
    view = UltraSettings::ApplicationView.new
    3.times { view.render }
    expect(runtime_settings.load_count).to eq 3
  end

  it "does not leak the reentrancy guard onto the thread" do
    UltraSettings::ApplicationView.new.render
    expect(Thread.current[:ultra_settings_runtime_settings_reloaded]).to be_nil
  end

  context "when the runtime settings cannot be reloaded" do
    let(:runtime_settings) do
      ReloadableRuntimeSettings.new({"my_service.timeout" => 2.5}, error: IOError.new("connection lost"))
    end

    it "still renders the page" do
      html = nil
      expect { html = UltraSettings::ApplicationView.new.render }.to output(/IOError: connection lost/).to_stderr
      expect(html).to be_a(String)
      expect(html).to match(/ultra-settings-config-detail/)
    end

    it "does not leak the reentrancy guard onto the thread" do
      expect { UltraSettings::ApplicationView.new.render }.to output.to_stderr
      expect(Thread.current[:ultra_settings_runtime_settings_reloaded]).to be_nil
    end
  end

  context "when the runtime settings do not support reloading" do
    let(:runtime_settings) { TestRuntimeSetings.new("my_service.timeout" => 2.5) }

    it "renders without error" do
      expect(UltraSettings::ApplicationView.new.render).to be_a(String)
      expect(UltraSettings::ConfigurationView.new(TestConfiguration.instance).render).to be_a(String)
      expect(UltraSettings::WebView.new.render_settings).to be_a(String)
    end
  end

  context "when there are no runtime settings" do
    let(:runtime_settings) { nil }

    it "renders without error" do
      expect(UltraSettings::ApplicationView.new.render).to be_a(String)
    end
  end
end
