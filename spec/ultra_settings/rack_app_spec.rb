# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe UltraSettings::RackApp do
  let(:rack_app) { UltraSettings::RackApp.new }

  it "renders the configuration page" do
    response = rack_app.call("PATH_INFO" => "/")
    expect(response[0]).to eq(200)
    expect(response[1]["content-type"]).to eq("text/html; charset=utf8")
    expect(response[2][0]).to be_a(String)
  end
end
