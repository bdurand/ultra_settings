# frozen_string_literal: true

require "spec_helper"
require "rack"

RSpec.describe UltraSettings do
  describe "adding configurations" do
    it "can add configurations to the root namespace" do
      expect(UltraSettings.test).to be_a(TestConfiguration)
      expect(UltraSettings.test2).to be_a(OtherConfiguration)
    end

    it "can detect if a class has been added" do
      UltraSettings.test
      expect(UltraSettings.added?(TestConfiguration)).to be(true)
      expect(UltraSettings.added?("TestConfiguration")).to be(true)
      expect(UltraSettings.added?(Object)).to be(false)
    end
  end

  describe "override!" do
    it "can override multiple configurations", env: {TEST_FOO: "test foo", OTHER_CONFIG_FOO: "other foo"} do
      expect(UltraSettings.test.foo).to eq("test foo")
      expect(UltraSettings.test2.foo).to eq("other foo")

      retval = UltraSettings.override!(test: {foo: "new test foo"}, test2: {foo: "new other foo"}) do
        expect(UltraSettings.test.foo).to eq("new test foo")
        expect(UltraSettings.test2.foo).to eq("new other foo")
        :ok
      end

      expect(retval).to eq(:ok)
      expect(UltraSettings.test.foo).to eq("test foo")
      expect(UltraSettings.test2.foo).to eq("other foo")
    end

    it "can override with an rspec helper", ultra_settings: {test: {foo: "new test foo"}} do
      expect(UltraSettings.test.foo).to eq("new test foo")
    end
  end

  describe "runtime_settings_url" do
    around do |example|
      save_val = UltraSettings.instance_variable_get(:@runtime_settings_url)
      begin
        example.run
      ensure
        UltraSettings.runtime_settings_url = save_val
      end
    end

    it "returns nil if not set" do
      UltraSettings.runtime_settings_url = nil
      expect(UltraSettings.runtime_settings_url(name: "foo", type: "string", description: "A test setting")).to be_nil
    end

    it "return nil if set to empty" do
      UltraSettings.runtime_settings_url = ""
      expect(UltraSettings.runtime_settings_url(name: "foo", type: "string", description: "A test setting")).to be_nil
    end

    it "returns the url with the ${name} placeholder replaced with the name argument" do
      UltraSettings.runtime_settings_url = "http://example.com/settings?filter=${name}"
      expect(UltraSettings.runtime_settings_url(name: "foo bar", type: "string", description: "A test setting")).to eq("http://example.com/settings?filter=foo+bar")
    end

    it "returns the url with the ${type} placeholder replaced with the type argument" do
      UltraSettings.runtime_settings_url = "http://example.com/settings?filter=${type}"
      expect(UltraSettings.runtime_settings_url(name: "foo bar", type: "string", description: "A test setting")).to eq("http://example.com/settings?filter=string")
    end

    it "returns the url with the ${description} placeholder replaced with the description argument" do
      UltraSettings.runtime_settings_url = "http://example.com/settings?filter=${description}"
      expect(UltraSettings.runtime_settings_url(name: "foo bar", type: "string", description: "A test setting")).to eq("http://example.com/settings?filter=A+test+setting")
    end
  end

  describe "super_settings_api_path" do
    around do |example|
      save_val = UltraSettings.instance_variable_get(:@super_settings_api_path)
      save_runtime = UltraSettings.instance_variable_get(:@runtime_settings)
      begin
        example.run
      ensure
        UltraSettings.instance_variable_set(:@super_settings_api_path, save_val)
        UltraSettings.runtime_settings = save_runtime
      end
    end

    it "returns nil by default" do
      UltraSettings.instance_variable_set(:@super_settings_api_path, nil)
      expect(UltraSettings.super_settings_api_path).to be_nil
    end

    it "stores a valid path" do
      stub_const("SuperSettings", Class.new)
      UltraSettings.super_settings_api_path = "/super_settings"
      expect(UltraSettings.super_settings_api_path).to eq("/super_settings")
    end

    it "strips trailing slashes from the path" do
      stub_const("SuperSettings", Class.new)
      UltraSettings.super_settings_api_path = "/super_settings/"
      expect(UltraSettings.super_settings_api_path).to eq("/super_settings")
    end

    it "raises an error if the path does not start with /" do
      stub_const("SuperSettings", Class.new)
      expect { UltraSettings.super_settings_api_path = "super_settings" }.to raise_error(ArgumentError)
    end

    it "raises an error if SuperSettings is not defined" do
      hide_const("SuperSettings")
      expect { UltraSettings.super_settings_api_path = "/super_settings" }.to raise_error(RuntimeError)
    end

    it "sets runtime_settings to SuperSettings when a path is provided" do
      stub_const("SuperSettings", Class.new)
      UltraSettings.super_settings_api_path = "/super_settings"
      expect(UltraSettings.instance_variable_get(:@runtime_settings)).to eq(SuperSettings)
    end

    it "can be set to nil to disable" do
      stub_const("SuperSettings", Class.new)
      UltraSettings.super_settings_api_path = "/super_settings"
      UltraSettings.super_settings_api_path = nil
      expect(UltraSettings.super_settings_api_path).to be_nil
    end
  end
end
