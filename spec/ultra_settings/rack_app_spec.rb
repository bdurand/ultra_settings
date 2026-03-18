# frozen_string_literal: true

require "spec_helper"
require "rack"

RSpec.describe UltraSettings::RackApp do
  let(:rack_app) { UltraSettings::RackApp.new }

  it "renders the configuration page" do
    response = rack_app.call("PATH_INFO" => "/")
    expect(response[0]).to eq(200)
    expect(response[1]["content-type"]).to eq("text/html; charset=utf8")
    expect(response[2][0]).to be_a(String)
  end

  it "renders the configuration page for any unknown path" do
    response = rack_app.call("PATH_INFO" => "/unknown/path")
    expect(response[0]).to eq(200)
    expect(response[1]["content-type"]).to eq("text/html; charset=utf8")
  end

  describe "locale resolution" do
    it "sets the locale from the lang query parameter" do
      response = rack_app.call("PATH_INFO" => "/", "QUERY_STRING" => "lang=es")
      body = response[2][0]
      expect(body).to include('lang="es"')
    end

    it "sets the locale from the ultra_settings_locale cookie" do
      response = rack_app.call("PATH_INFO" => "/", "HTTP_COOKIE" => "ultra_settings_locale=fr")
      body = response[2][0]
      expect(body).to include('lang="fr"')
    end

    it "sets the locale from the Accept-Language header" do
      response = rack_app.call("PATH_INFO" => "/", "HTTP_ACCEPT_LANGUAGE" => "de-DE,de;q=0.9,en;q=0.8")
      body = response[2][0]
      expect(body).to include('lang="de"')
    end

    it "prefers query parameter over cookie and header" do
      response = rack_app.call(
        "PATH_INFO" => "/",
        "QUERY_STRING" => "lang=ja",
        "HTTP_COOKIE" => "ultra_settings_locale=fr",
        "HTTP_ACCEPT_LANGUAGE" => "de"
      )
      body = response[2][0]
      expect(body).to include('lang="ja"')
    end

    it "prefers cookie over Accept-Language header" do
      response = rack_app.call(
        "PATH_INFO" => "/",
        "HTTP_COOKIE" => "ultra_settings_locale=ko",
        "HTTP_ACCEPT_LANGUAGE" => "de"
      )
      body = response[2][0]
      expect(body).to include('lang="ko"')
    end

    it "falls back to default locale when no locale is specified" do
      response = rack_app.call("PATH_INFO" => "/")
      body = response[2][0]
      expect(body).to include('lang="en"')
    end
  end
end
