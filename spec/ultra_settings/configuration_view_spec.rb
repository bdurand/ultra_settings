# frozen_string_literal: true

require_relative "../spec_helper"

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

    it "renders links for the runtime settings" do
      UltraSettings.runtime_settings_url = "http://example.com/settings?filter=${name}"
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      expect(html).to include('href="http://example.com/settings?filter=test.string"')
    end
  end
end
