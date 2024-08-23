# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::ConfigurationView do
  it "renders the confguration as an HTML table" do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render
    expect(html.strip).to match(/\A<table class="ultra-settings-table">.*<\/table>\z/m)
  end

  it "can set the table class" do
    html = UltraSettings::ConfigurationView.new(TestConfiguration.instance).render(table_class: "table table-striped")
    expect(html.strip).to match(/\A<table class="table table-striped">.*<\/table>\z/m)
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
end
