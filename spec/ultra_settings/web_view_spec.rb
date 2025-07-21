# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::WebView do
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
    docs = parse_with_svg(app.content)
    docs.each do |doc|
      expect(doc.errors).to be_empty
    end
  end
end
