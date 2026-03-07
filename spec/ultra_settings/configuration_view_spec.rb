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

  describe "super_settings editing" do
    around do |example|
      save_editing = UltraSettings.instance_variable_get(:@super_settings_editing)
      save_runtime = UltraSettings.instance_variable_get(:@runtime_settings)
      begin
        example.run
      ensure
        UltraSettings.instance_variable_set(:@super_settings_editing, save_editing)
        UltraSettings.runtime_settings = save_runtime
      end
    end

    it "renders edit buttons when super_settings editing is enabled", settings: {} do
      stub_const("SuperSettings", Class.new {
        def self.[](key)
          nil
        end
      })
      UltraSettings.super_settings_editing = true
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance, can_edit_super_settings: true).render
      expect(html).to include("ultra-settings-ss-edit-btn")
      expect(html).to include('data-ss-key="test.string"')
    end

    it "does not render edit buttons when super_settings editing is disabled", settings: {} do
      stub_const("SuperSettings", Class.new {
        def self.[](key)
          nil
        end
      })
      UltraSettings.super_settings_editing = false
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance, can_edit_super_settings: false).render
      expect(html).not_to include("ultra-settings-ss-edit-btn")
    end

    it "includes default type from the field type", settings: {} do
      stub_const("SuperSettings", Class.new {
        def self.[](key)
          nil
        end
      })
      UltraSettings.super_settings_editing = true
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance, can_edit_super_settings: true).render
      expect(html).to include('data-ss-default-type="integer"')
      expect(html).to include('data-ss-default-type="boolean"')
      expect(html).to include('data-ss-default-type="float"')
    end

    it "includes default description from the field description", settings: {} do
      stub_const("SuperSettings", Class.new {
        def self.[](key)
          nil
        end
      })
      UltraSettings.super_settings_editing = true
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance, can_edit_super_settings: true).render
      expect(html).to include('data-ss-default-description="An all purpose foo setting"')
    end

    it "maps symbol type to string for super_settings", settings: {} do
      stub_const("SuperSettings", Class.new {
        def self.[](key)
          nil
        end
      })
      UltraSettings.super_settings_editing = true
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance, can_edit_super_settings: true).render
      # The :symbol field should map to "string" for SuperSettings
      doc = Nokogiri::HTML5(html)
      symbol_btn = doc.css('.ultra-settings-ss-edit-btn[data-ss-key="test.symbol"]')
      expect(symbol_btn.first&.attr("data-ss-default-type")).to eq("string")
    end
  end
end
