# frozen_string_literal: true

require_relative "spec_helper"

describe UltraSettings do
  describe "adding configurations" do
    it "can add configurations to the root namespace" do
      expect(UltraSettings.test).to be_a(TestConfiguration)
      expect(UltraSettings.test2).to be_a(OtherConfiguration)
    end

    it "can detect if a class has been added" do
      UltraSettings.test
      expect(UltraSettings.include?(TestConfiguration)).to be(true)
      expect(UltraSettings.include?("TestConfiguration")).to be(true)
      expect(UltraSettings.include?(Object)).to be(false)
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
end
