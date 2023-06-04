# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::RackApp do
  it "renders the configuration HTML page" do
    app = UltraSettings::WebApp.new
    expect(app.render_settings).to be_a(String)
  end
end
