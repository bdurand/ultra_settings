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

  it "renders in the requested locale" do
    app = UltraSettings::WebView.new
    expect(app.render_settings(locale: "fr")).to include('<html lang="fr"')
    expect(app.render_settings(locale: "en")).to include('<html lang="en"')
  end

  it "does not store request state on the shared instance" do
    app = UltraSettings::WebView.new
    app.render_settings(locale: "fr")
    expect(app.instance_variable_get(:@locale)).to be_nil
  end

  it "renders each request with its own locale when called concurrently" do
    app = UltraSettings::WebView.new
    mismatches = Queue.new

    threads = ["en", "fr", "es", "de"].map do |locale|
      Thread.new do
        10.times do
          html = app.render_settings(locale: locale)
          mismatches << locale unless html.include?("<html lang=\"#{locale}\"")
        end
      end
    end
    threads.each(&:join)

    expect(mismatches.size).to eq 0
  end
end
