# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::ApplicationView do
  it "renders the configuration as an HTML application with multiple configurations" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).to match(/class="ultra-settings-config-list"/)
    expect(html).to match(/ultra-settings-config-detail/m)
    expect(html).to match(/<script>.*<\/script>/m)
  end

  it "does not render the language menu (moved to layout)" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).not_to include('id="ultra-settings-language-menu"')
  end

  it "renders the configuration CSS" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).to match(/<style type="text\/css">.*<\/style>/m)
  end

  it "maintains backward compatibility with table class parameter" do
    html = UltraSettings::ApplicationView.new.render(table_class: "table table-striped")
    # The table_class parameter is still accepted but doesn't affect the new card layout
    expect(html).to match(/ultra-settings-fields/m)
  end

  it "renders valid HTML", env: {TEST_STRING: "<script"} do
    html = UltraSettings::ApplicationView.new.render
    doc = Nokogiri::HTML5(html)
    expect(doc.errors).to be_empty
  end

  it "returns a style tag with the CSS" do
    app_view = UltraSettings::ApplicationView.new
    style_tag = app_view.style_tag
    expect(style_tag).to start_with("<style type=\"text/css\">")
    expect(style_tag).to end_with("</style>")
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

    it "renders the edit panel when super_settings_api_path is set", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ApplicationView.new.render
      expect(html).to include('data-ss-api-path="/super_settings"')
      expect(html).to include("ultra-settings-ss-panel")
    end

    it "does not render the edit panel when super_settings_api_path is nil" do
      UltraSettings.instance_variable_set(:@super_settings_api_path, nil)
      html = UltraSettings::ApplicationView.new.render
      expect(html).not_to include("data-ss-api-path")
      expect(html).not_to include('id="ultra-settings-ss-panel"')
    end

    it "renders valid HTML with super_settings_api_path set", settings: {} do
      UltraSettings.super_settings_api_path = "/super_settings"
      html = UltraSettings::ApplicationView.new.render
      doc = Nokogiri::HTML5(html)
      expect(doc.errors).to be_empty
    end
  end
end
