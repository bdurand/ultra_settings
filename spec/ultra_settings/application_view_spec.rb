# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::ApplicationView do
  it "renders the configuration as an HTML application with multiple configurations" do
    html = UltraSettings::ApplicationView.new.render
    expect(html).to match(/class="ultra-settings-dropdown"/)
    expect(html).to match(/ultra-settings-fields/m)
    expect(html).to match(/<script>.*<\/script>/m)
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
end
