# frozen_string_literal: true

require_relative "../spec_helper"

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
end
