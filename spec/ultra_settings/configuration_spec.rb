# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::Configuration do
  let(:configuration) { TestConfiguration.instance }
  let(:other_configuration) { OtherConfiguration.instance }
  let(:subclass_configuration) { SubclassConfiguration.instance }
  let(:namespace_configuration) { Test::NamespaceConfiguration.instance }
  let(:disabled_configuration) { DisabledSourcesConfiguration.instance }
  let(:config_path) { UltraSettings::Configuration.yaml_config_path }

  describe "field" do
    it "defines a string field by default" do
      expect(configuration.foo).to eq "foo value"
    end

    it "uses the environment specific configuration file values" do
      expect(configuration.bar).to eq "test value"
    end

    it "defines a field with a type" do
      expect(configuration.symbol).to eq :symbol_value
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

    it "can override the environment variable delimiter and upcase", env: {test__namespace__foo: "val"} do
      expect(namespace_configuration.foo).to eq "val"
    end

    it "uses the environment if env_var is true", env: {TEST_ALL_ENABLED: "env test"} do
      expect(configuration.all_enabled).to eq "env test"
    end

    it "does not use the environment if env_var is false", env: {TEST_ALL_DISABLED: "env test"} do
      expect(configuration.all_disabled).to be_nil
    end

    it "can disable the environment variables by default", env: {FOO: "foo", BAR: "bar"} do
      expect(disabled_configuration.foo).to be_nil
      expect(disabled_configuration.bar).to eq "bar"
    end
  end

  describe "runtime settings" do
    it "uses the class name as a setting prefix", settings: {"test.foo" => "setting test"} do
      expect(configuration.foo).to eq "setting test"
    end

    it "can override the default setting prefix", settings: {"other_config_foo" => "setting test"} do
      expect(other_configuration.foo).to eq "setting test"
    end

    it "can use a specific setting name", settings: {specific_setting: "setting test"} do
      expect(configuration.setting).to eq "setting test"
    end

    it "can override the setting delimiter and upcase", settings: {"TEST->NAMESPACE->FOO" => "val"} do
      expect(namespace_configuration.foo).to eq "val"
    end

    it "uses the settings if runtime_setting is true", settings: {"test.all_enabled" => "test"} do
      expect(configuration.all_enabled).to eq "test"
    end

    it "does not use the settings if runtime_setting is false", settings: {"test.all_disabled" => "test"} do
      expect(configuration.all_disabled).to be_nil
    end

    it "can disable the runtime settings by default", settings: {foo: "foo", bar: "bar"} do
      expect(disabled_configuration.foo).to be_nil
      expect(disabled_configuration.bar).to eq "bar"
    end
  end

  describe "YAML key" do
    it "uses the name as the YAML key" do
      expect(configuration.foo).to eq "foo value"
    end

    it "can override the default YAML key" do
      expect(configuration.yaml_key).to eq "specific value"
    end

    it "can override the default YAML directory" do
      path = config_path.join("my_settings", "test", "namespace.yml")
      expect(Test::NamespaceConfiguration.configuration_file).to eq path
    end

    it "uses the YAML config if yaml_key is true" do
      expect(configuration.all_enabled).to eq "yaml value"
    end

    it "does not use YAML config if yaml_key is false" do
      expect(configuration.all_disabled).to be_nil
    end

    it "can disable the YAML config by default" do
      expect(disabled_configuration.foo).to be_nil
      expect(disabled_configuration.bar).to eq "bar"
    end

    it "flattens the YAML config so nested values can be referenced with a string key" do
      expect(other_configuration.baz).to eq "nested value"
    end
  end

  describe "configuration file" do
    it "gets the file path from the class name" do
      expect(TestConfiguration.configuration_file).to eq config_path.join("test.yml")
    end

    it "can override the file path" do
      expect(OtherConfiguration.configuration_file).to eq config_path.join("other_config.yml")
    end
  end

  describe "subclasses" do
    it "inherits values from the parent class", env: {TEST_FOO: "one", SUBCLASS_FOO: "two"} do
      expect(configuration.foo).to eq "one"
      expect(subclass_configuration.include?(:foo)).to eq true
      expect(subclass_configuration.foo).to eq "one"
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
end
