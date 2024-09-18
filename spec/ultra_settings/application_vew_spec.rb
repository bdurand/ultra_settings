# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::ApplicationView do
  it "renders the confguration as an HTML application" do
    html = UltraSettings::ApplicationView.new.render
    expect(html.strip).to match(/<select class="ultra-settings-select" size="1" id="config-selector">.*<\/select>/m)
    expect(html.strip).to match(/<table class="ultra-settings-table">.*<\/table>/m)
    expect(html.strip).to match(/<script>.*<\/script>/m)
  end

  it "can set the select class" do
    html = UltraSettings::ApplicationView.new.render(select_class: "form-control")
    expect(html.strip).to match(/<select class="form-control" size="1" id="config-selector">.*<\/select>/m)
  end

  it "can set the table class" do
    html = UltraSettings::ApplicationView.new.render(table_class: "table table-striped")
    expect(html.strip).to match(/<table class="table table-striped">.*<\/table>/m)
  end

  it "renders valid HTML", env: {TEST_STRING: "<script"} do
    html = UltraSettings::ApplicationView.new.render
    doc = Nokogiri::HTML(html)
    expect(doc.errors).to be_empty
  end
end
