# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::WebView do
  it "renders the configuration HTML page" do
    app = UltraSettings::WebView.new
    expect(app.render_settings).to be_a(String)
  end

  it "renders the configuration content" do
    app = UltraSettings::WebView.new
    expect(app.content).to be_a(String)
  end

  it "renders valid HTML" do
    app = UltraSettings::WebView.new
    doc = Nokogiri::HTML5(app.content)
    expect(doc.errors).to be_empty
  end

  it "renders the language menu in the footer" do
    html = UltraSettings::WebView.new.render_settings
    expect(html).to include('id="ultra-settings-language-menu"')
    expect(html).to include('class="ultra-settings-language-popup"')
    expect(html).to match(/ultra-settings-page-footer.*ultra-settings-language-menu/m)
  end
end
