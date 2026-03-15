# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::ConfigurationView do
  it "renders the configuration as HTML" do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    expect(html.strip).to match(/\A.*ultra-settings-fields.*\z/m)
  end

  it "escapes HTML in the configuration values", env: {TEST_STRING: "<script>"} do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    expect(html).to include("&lt;script&gt;")
    expect(html).not_to include("<script>")
  end

  it "renders secret fields as dots", env: {TEST_SECRET: "secretvalue"} do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    expect(html).to include("••••••••")
    expect(html).not_to include("secretvalue")
  end

  it "renders valid HTML", env: {TEST_STRING: "<script"} do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    doc = Nokogiri::HTML5(html)
    expect(doc.errors).to be_empty
  end

  describe "links to runtime settings" do
    around do |example|
      save_val = UltraSettings.instance_variable_get(:@runtime_settings_url)
      begin
        example.run
      ensure
        UltraSettings.runtime_settings_url = save_val
      end
    end

    it "does not render links if the runtime settings URL is not set" do
      UltraSettings.runtime_settings_url = nil
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).not_to include("<a href=")
    end

    it "renders links for the runtime settings", settings: {} do
      UltraSettings.runtime_settings_url = "http://example.com/settings?filter=${name}"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).to include('href="http://example.com/settings?filter=test.string"')
    end
  end

  describe "super_settings_api_path", skip: !defined?(::SuperSettings) && "super_settings gem is not available" do
    around do |example|
      save_val = UltraSettings.instance_variable_get(:@super_settings_api_path)
      begin
        example.run
      ensure
        UltraSettings.instance_variable_set(:@super_settings_api_path, save_val)
      end
    end

    it "renders edit buttons when super_settings_api_path is set", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).to include("ultra-settings-ss-edit-btn")
      expect(html).to include('data-ss-key="test.string"')
    end

    it "does not render edit buttons when super_settings_api_path is nil", settings: {} do
      UltraSettings.instance_variable_set(:@super_settings_api_path, nil)
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).not_to include("ultra-settings-ss-edit-btn")
    end

    it "includes default type from the field type", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).to include('data-ss-default-type="integer"')
      expect(html).to include('data-ss-default-type="boolean"')
      expect(html).to include('data-ss-default-type="float"')
    end

    it "includes default description from the field description", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).to include('data-ss-default-description="An all purpose foo setting"')
    end

    it "maps symbol type to string for super_settings", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      symbol_btn = doc.css('.ultra-settings-ss-edit-btn[data-ss-key="test.symbol"]')
      expect(symbol_btn.first&.attr("data-ss-default-type")).to eq("string")
    end
  end
end
