# frozen_string_literal: true

require "spec_helper"
require "rack"
require "stringio"

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

  describe "super_settings editing API" do
    let(:mock_rest_api) { double("SuperSettings::RestAPI") }

    around do |example|
      save_editing = UltraSettings.instance_variable_get(:@super_settings_editing)
      save_runtime = UltraSettings.instance_variable_get(:@runtime_settings)
      begin
        example.run
      ensure
        UltraSettings.instance_variable_set(:@super_settings_editing, save_editing)
        UltraSettings.runtime_settings = save_runtime
      end
    end

    before do
      stub_const("SuperSettings", Module.new)
      stub_const("SuperSettings::RestAPI", mock_rest_api)
      UltraSettings.super_settings_editing = true
      UltraSettings.runtime_settings = TestRuntimeSetings.new
    end

    describe "GET /super_settings/setting" do
      it "returns a setting when found" do
        setting_data = {key: "test.foo", value: "bar", value_type: "string", description: "Test"}
        allow(mock_rest_api).to receive(:show).with("test.foo").and_return(setting_data)

        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "QUERY_STRING" => "key=test.foo",
          "REQUEST_METHOD" => "GET"
        )

        expect(response[0]).to eq(200)
        expect(response[1]["content-type"]).to eq("application/json; charset=utf-8")
        body = JSON.parse(response[2][0])
        expect(body["key"]).to eq("test.foo")
        expect(body["value"]).to eq("bar")
      end

      it "returns 404 when setting not found" do
        allow(mock_rest_api).to receive(:show).with("test.missing").and_return(nil)

        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "QUERY_STRING" => "key=test.missing",
          "REQUEST_METHOD" => "GET"
        )

        expect(response[0]).to eq(404)
      end

      it "returns 400 when key parameter is missing" do
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "QUERY_STRING" => "",
          "REQUEST_METHOD" => "GET"
        )

        expect(response[0]).to eq(400)
      end
    end

    describe "POST /super_settings/setting" do
      it "saves a setting successfully" do
        allow(mock_rest_api).to receive(:update)
          .with([{"key" => "test.foo", "value" => "new_val", "value_type" => "string"}])
          .and_return({success: true})

        body = JSON.generate({settings: [{key: "test.foo", value: "new_val", value_type: "string"}]})
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new(body),
          "CONTENT_TYPE" => "application/json"
        )

        expect(response[0]).to eq(200)
        result = JSON.parse(response[2][0])
        expect(result["success"]).to be(true)
      end

      it "returns errors on validation failure" do
        allow(mock_rest_api).to receive(:update)
          .and_return({success: false, errors: {"test.foo" => ["value must be an integer"]}})

        body = JSON.generate({settings: [{key: "test.foo", value: "abc", value_type: "integer"}]})
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new(body),
          "CONTENT_TYPE" => "application/json"
        )

        expect(response[0]).to eq(422)
        result = JSON.parse(response[2][0])
        expect(result["success"]).to be(false)
        expect(result["errors"]).to have_key("test.foo")
      end

      it "returns 400 for invalid JSON body" do
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new("not json"),
          "CONTENT_TYPE" => "application/json"
        )

        expect(response[0]).to eq(400)
      end

      it "returns 400 when settings parameter is missing" do
        body = JSON.generate({foo: "bar"})
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new(body),
          "CONTENT_TYPE" => "application/json"
        )

        expect(response[0]).to eq(400)
      end
    end

    describe "when super_settings editing is disabled" do
      before do
        UltraSettings.super_settings_editing = false
      end

      it "does not handle API routes and returns HTML instead" do
        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "QUERY_STRING" => "key=test.foo",
          "REQUEST_METHOD" => "GET"
        )

        expect(response[0]).to eq(200)
        expect(response[1]["content-type"]).to eq("text/html; charset=utf8")
      end
    end

    describe "when super_settings editing uses a lambda" do
      before do
        UltraSettings.super_settings_editing = ->(request) { request.path == "/super_settings/setting" }
      end

      it "allows API routes when the lambda returns true" do
        setting_data = {key: "test.foo", value: "bar", value_type: "string", description: "Test"}
        allow(mock_rest_api).to receive(:show).with("test.foo").and_return(setting_data)

        response = rack_app.call(
          "PATH_INFO" => "/super_settings/setting",
          "QUERY_STRING" => "key=test.foo",
          "REQUEST_METHOD" => "GET"
        )

        expect(response[0]).to eq(200)
        expect(response[1]["content-type"]).to eq("application/json; charset=utf-8")
      end
    end
  end
end
