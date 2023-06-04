# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::RackApp do
  let(:app) { lambda { |env| [200, {}, ["OK"]] } }
  let(:rack_app) { UltraSettings::RackApp.new(app) }

  it "renders the configuration page" do
    response = rack_app.call("PATH_INFO" => "/")
    expect(response[0]).to eq(200)
    expect(response[1]["Content-Type"]).to eq("text/html; charset=utf8")
    expect(response[2][0]).to be_a(String)
  end

  it "renders not found if the path is not /" do
    response = rack_app.call("PATH_INFO" => "/foo")
    expect(response).to eq([200, {}, ["OK"]])
  end
end
