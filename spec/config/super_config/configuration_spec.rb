# frozen_string_literal: true

require_relative "../../spec_helper"

describe SuperConfig::Configuration do
  let(:configuration) { TestConfiguration.new }
  let(:other_configuration) { OtherConfiguration.new }

  describe "define" do
    it "defines a string field by default" do
      expect(configuration.foo).to eq "foo value"
    end

    it "uses the environment specific configuration file values" do
      expect(configuration.bar).to eq "test value"
    end

    it "defines a field with a type" do
      expect(configuration.int).to eq 1
      expect(configuration.float).to eq 1.1
      expect(configuration.bool).to eq true
      expect(configuration.bool?).to eq true
      expect(configuration.time).to eq Time.utc(2023, 5, 25, 19, 6)
      expect(configuration.array).to eq ["1", "2", "3"]
    end

    it "defines a field with a default" do
      expect(configuration.default_int).to eq 1
      expect(configuration.default_bool).to eq true
    end

    it "defines a static field that cannot change", env: {TEST_STATIC: "original value"} do
      expect(configuration.static).to eq "original value"
      ClimateControl.modify(TEST_STATIC: "new value") do
        expect(configuration.static).to eq "original value"
      end
    end

    it "can reference fields like a hash" do
      expect(configuration[:foo]).to eq "foo value"
      expect(configuration.include?(:foo)).to eq true

      expect(configuration[:not_exist]).to eq nil
      expect(configuration.include?(:not_exist)).to eq false
    end
  end

  describe "environment variables" do
    it "uses the class name as an environment variable prefix", env: {TEST_FOO: "env test"} do
      expect(configuration.foo).to eq "env test"
    end

    it "can override the environment variable prefix", env: {OTHER_CONFIG_FOO: "env test"} do
      expect(other_configuration.foo).to eq "env test"
    end

    it "can use a specific environment variable name"

    it "can disable the environment variables"
  end

  describe "setting names" do
    it "uses the class name as a setting prefix"

    it "can override the default setting prefix"

    it "can use a specific setting name"

    it "can disable the settings"
  end

  describe "YAML key" do
    it "uses the name as the YAML key"

    it "can override the default YAML key"

    it "can disable the YAML configuration"
  end

  describe "configuration file" do
    it "gets the file path from the class name"

    it "can override the file path"
  end

  describe "subclasses" do
    it "inherits definitions from the parent class"
  end

  describe "during initialization" do
    it "raises an error when referencing a non-static value during initialization" do
      allow(Rails.application).to receive(:initialized?).and_return(false)
      expect { configuration.static }.to_not raise_error
      expect { configuration.foo }.to raise_error(SuperConfig::NonStaticValueError)
    end
  end
end
