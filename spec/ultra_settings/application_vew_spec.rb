# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe UltraSettings::ApplicationView do
  it "renders the configuration as an HTML application" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).to match(/<select class="ultra-settings-select" size="1" id="config-selector">.*<\/select>/m)
    expect(html).to match(/ultra-settings-fields/m)
    expect(html).to match(/<script>.*<\/script>/m)
  end

  it "renders the configuration CSS" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).to match(/<style type="text\/css">.*<\/style>/m)
  end

  it "can set the select class" do
    html = UltraSettings::ApplicationView.new.render(select_class: "form-control")
    expect(html).to match(/<select class="form-control" size="1" id="config-selector">.*<\/select>/m)
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
end
