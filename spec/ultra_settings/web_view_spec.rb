# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::WebView do
  it "renders the configuration HTML page" do
    app = UltraSettings::WebView.new
    expect(app.render_settings).to be_a(String)
  end

  it "renders the configuration CSS" do
    app = UltraSettings::WebView.new
    expect(app.css).to be_a(String)
  end

  it "renders the configuration content" do
    app = UltraSettings::WebView.new
    expect(app.content).to be_a(String)
  end
end
