# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::Configuration do
  let(:configuration) { TestConfiguration.instance }
  let(:other_configuration) { OtherConfiguration.instance }
  let(:subclass_configuration) { SubclassConfiguration.instance }

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
      configuration.instance_variable_get(:@memoized_values).clear
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

    it "can use a specific environment variable name", env: {SPECIFIC_ENV_VAR: "env test"} do
      expect(configuration.env_var).to eq "env test"
    end

    it "can disable the environment variables", env: {TEST_FOO: "env value", OTHER_CONFIG_FOO: "other value"} do
      expect(configuration.foo).to eq "env value"
      expect(other_configuration.foo).to eq "other value"
      begin
        TestConfiguration.environment_variables_disabled = true
        expect(configuration.foo).to eq "foo value"
        expect(other_configuration.foo).to eq "other value"
      ensure
        TestConfiguration.environment_variables_disabled = false
      end
    end
  end

  describe "setting names" do
    it "uses the class name as a setting prefix", settings: {"test.foo" => "setting test"} do
      expect(configuration.foo).to eq "setting test"
    end

    it "can override the default setting prefix", settings: {"other_config_foo" => "setting test"} do
      expect(other_configuration.foo).to eq "setting test"
    end

    it "can use a specific setting name", settings: {specific_setting: "setting test"} do
      expect(configuration.setting).to eq "setting test"
    end

    it "can disable the settings", settings: {"test.foo" => "settings value", "other_config_foo" => "other value"} do
      expect(configuration.foo).to eq "settings value"
      expect(other_configuration.foo).to eq "other value"
      begin
        TestConfiguration.runtime_settings_disabled = true
        expect(configuration.foo).to eq "foo value"
        expect(other_configuration.foo).to eq "other value"
      ensure
        TestConfiguration.runtime_settings_disabled = false
      end
    end
  end

  describe "YAML key" do
    it "uses the name as the YAML key" do
      expect(configuration.foo).to eq "foo value"
    end

    it "can override the default YAML key" do
      expect(configuration.yaml_key).to eq "specific value"
    end

    it "can disable the YAML configuration" do
      expect(configuration.foo).to eq "foo value"
      expect(other_configuration.foo).to eq "2"
      begin
        TestConfiguration.yaml_config_disabled = true
        expect(configuration.foo).to eq nil
        expect(other_configuration.foo).to eq "2"
      ensure
        TestConfiguration.yaml_config_disabled = false
      end
    end
  end

  describe "configuration file" do
    it "gets the file path from the class name" do
      expect(TestConfiguration.configuration_file).to eq Rails.root.join("config", "test.yml")
    end

    it "can override the file path" do
      expect(OtherConfiguration.configuration_file).to eq Rails.root.join("config", "other_config.yml")
    end
  end

  describe "subclasses" do
    it "inherits definitions from the parent class", env: {TEST_FOO: "one", SUBCLASS_FOO: "two"} do
      expect(configuration.foo).to eq "one"
      expect(subclass_configuration.foo).to eq "two"
    end

    it "can override field definitions", env: {TEST_BAR: "1", SUBCLASS_BAR: "2"} do
      expect(configuration.bar).to eq "1"
      expect(subclass_configuration.bar).to eq 2
    end

    it "can define new fields" do
      expect(subclass_configuration).to respond_to(:sub)
      expect(configuration).to_not respond_to(:sub)
    end
  end

  describe "during initialization" do
    it "raises an error when referencing a non-static value during initialization" do
      allow(Rails.application).to receive(:initialized?).and_return(false)
      expect { configuration.static }.to_not raise_error
      expect { configuration.foo }.to raise_error(UltraSettings::NonStaticValueError)
    end
  end
end
