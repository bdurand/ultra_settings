# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

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

  describe "copy buttons" do
    it "renders a copy button with the raw value for fields that are not secret", env: {TEST_STRING: "hello world"} do
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      button = doc.at_css('.ultra-settings-field-card[data-field-name="string"] .ultra-settings-copy-btn')
      expect(button).not_to be_nil
      expect(button["disabled"]).to be_nil
      expect(button["data-copy-value"]).to eq("hello world")
    end

    it "renders a disabled copy button without a value for secret fields", env: {TEST_SECRET: "secretvalue"} do
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      button = doc.at_css('.ultra-settings-field-card[data-field-name="secret"] .ultra-settings-copy-btn')
      expect(button).not_to be_nil
      expect(button["disabled"]).not_to be_nil
      expect(button["data-copy-value"]).to be_nil
      expect(html).not_to include("secretvalue")
    end

    it "does not render a copy button for fields that have no value", env: {TEST_STRING: nil} do
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      card = doc.at_css('.ultra-settings-field-card[data-field-name="string"]')
      expect(card.at_css(".ultra-settings-field-value.nil")).not_to be_nil
      expect(card.at_css(".ultra-settings-copy-btn")).to be_nil
      expect(card.at_css(".ultra-settings-copy-placeholder")).not_to be_nil
    end

    it "copies values without the quoting used for display", env: {TEST_ARRAY: "a,b", TEST_INT: "42"} do
      view = UltraSettings::ConfigurationView.new(TestConfiguration.instance)
      expect(view.send(:copy_value, "hello world")).to eq("hello world")
      expect(view.send(:copy_value, 42)).to eq("42")
      expect(view.send(:copy_value, ["a", "b"])).to eq("a\nb")
      expect(view.send(:copy_value, nil)).to eq("")
      expect(view.send(:copy_value, Time.utc(2025, 1, 15, 10, 30, 0))).to eq("2025-01-15T10:30:00Z")
    end
  end

  it "renders valid HTML", env: {TEST_STRING: "<script"} do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    doc = Nokogiri::HTML5(html)
    expect(doc.errors).to be_empty
  end

  describe "YAML keys toggle" do
    it "does not render the toggle if the YAML file exists" do
      html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      expect(TestConfiguration.configuration_file).to exist
      expect(doc.at_css(".ultra-settings-yaml-toggle")).to be_nil
      expect(doc.at_css(".ultra-settings-block")["class"]).not_to include("ultra-settings-yaml-hidden")
    end

    it "renders the toggle in the off state if the YAML file does not exist" do
      html = UltraSettings::ConfigurationView.new(Test::NamespaceConfiguration.instance).render
      doc = Nokogiri::HTML5(html)
      expect(Test::NamespaceConfiguration.configuration_file).not_to exist

      toggle = doc.at_css(".ultra-settings-yaml-toggle")
      expect(toggle["role"]).to eq("switch")
      expect(toggle["aria-checked"]).to eq("false")
      expect(toggle.text.strip).to eq("show keys")

      expect(doc.at_css(".ultra-settings-block")["class"]).to include("ultra-settings-yaml-hidden")
      expect(doc.at_css('.ultra-settings-source-row[data-source="yaml"]')).not_to be_nil
    end
  end

  describe "configuration file path" do
    around do |example|
      save_val = UltraSettings::Configuration.yaml_config_path
      begin
        example.run
      ensure
        UltraSettings::Configuration.yaml_config_path = save_val
      end
    end

    it "shows the path relative to the working directory" do
      view = UltraSettings::ConfigurationView.new(TestConfiguration.instance)
      path = Pathname.new(Dir.pwd).join("config", "settings", "test.yml")
      expect(view.send(:relative_path, path)).to eq("config/settings/test.yml")
    end

    it "shows the path relative to the configuration directory if it is outside the working directory" do
      Dir.mktmpdir do |tmpdir|
        config_dir = Pathname.new(File.realpath(tmpdir)).join("settings")
        UltraSettings::Configuration.yaml_config_path = config_dir
        view = UltraSettings::ConfigurationView.new(TestConfiguration.instance)
        expect(view.send(:relative_path, config_dir.join("test.yml"))).to eq("test.yml")
      end
    end

    it "does not show a relative prefix when the path goes through a symlinked directory" do
      Dir.mktmpdir do |tmpdir|
        tmp_path = Pathname.new(File.realpath(tmpdir))
        app_dir = tmp_path.join("app")
        app_dir.join("config").mkpath
        link_dir = tmp_path.join("app_link")
        File.symlink(app_dir.to_s, link_dir.to_s)

        Dir.chdir(app_dir.to_s) do
          UltraSettings::Configuration.yaml_config_path = link_dir.join("config")
          view = UltraSettings::ConfigurationView.new(TestConfiguration.instance)
          path = link_dir.join("config", "test.yml")
          expect(view.send(:relative_path, path)).to eq("config/test.yml")
        end
      end
    end

    it "shows the absolute path if the file is outside of the working and configuration directories" do
      Dir.mktmpdir do |tmpdir|
        UltraSettings::Configuration.yaml_config_path = Pathname.new(File.realpath(tmpdir))
        view = UltraSettings::ConfigurationView.new(TestConfiguration.instance)
        path = Pathname.new("/other/place/test.yml")
        expect(view.send(:relative_path, path)).to eq("/other/place/test.yml")
      end
    end
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
