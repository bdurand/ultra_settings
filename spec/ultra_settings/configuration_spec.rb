# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe UltraSettings::Configuration do
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

    it "defines a field with a Proc condition for using the default" do
      expect(configuration.default_if_proc).to eq 1
      ClimateControl.modify(TEST_DEFAULT_IF_PROC: "2") do
        expect(configuration.default_if_proc).to eq 2
      end
      ClimateControl.modify(TEST_DEFAULT_IF_PROC: "-3") do
        expect(configuration.default_if_proc).to eq 1
      end
    end

    it "defines a field with a method condition for using the default" do
      expect(configuration.default_if_method).to eq 1
      ClimateControl.modify(TEST_DEFAULT_IF_METHOD: "2") do
        expect(configuration.default_if_method).to eq 2
      end
      ClimateControl.modify(TEST_DEFAULT_IF_METHOD: "-3") do
        expect(configuration.default_if_method).to eq 1
      end
    end

    it "defines a static field that cannot change", env: {TEST_STATIC: "original value"} do
      configuration.instance_variable_get(:@ultra_settings_memoized_values).clear
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

    it "can use runtime settings for secret values if the engine is secure", settings: {"test.secret" => "test"} do
      expect(configuration.secret).to eq "test"
      begin
        UltraSettings.runtime_settings_secure = false
        expect(configuration.secret).to eq "secret_token" # value from yaml
      ensure
        UltraSettings.runtime_settings_secure = true
      end
      expect(configuration.secret).to eq "test"
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

    it "returns nil if the YAML load path is not set" do
      expect(SubclassConfiguration.configuration_file).to be_nil
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

  describe "descendant_configurations" do
    it "returns all descendant configuration classes" do
      descendants = UltraSettings::Configuration.descendant_configurations

      # Should include direct subclasses
      expect(descendants).to include(TestConfiguration)
      expect(descendants).to include(OtherConfiguration)
      expect(descendants).to include(DisabledSourcesConfiguration)
      expect(descendants).to include(MyServiceConfiguration)
      expect(descendants).to include(ExplicitConfiguration)
      expect(descendants).to include(Test::NamespaceConfiguration)

      # Should include nested subclasses (SubclassConfiguration is a subclass of TestConfiguration)
      expect(descendants).to include(SubclassConfiguration)
    end

    it "returns an empty array when there are no descendants" do
      # Create a new configuration class with no subclasses
      test_class = Class.new(UltraSettings::Configuration)
      expect(test_class.descendant_configurations).to eq([])
    end

    it "handles multiple levels of inheritance" do
      # SubclassConfiguration inherits from TestConfiguration
      # So TestConfiguration.descendant_configurations should include SubclassConfiguration
      descendants = TestConfiguration.descendant_configurations
      expect(descendants).to include(SubclassConfiguration)
    end
  end

  describe "override!" do
    it "can hard code values for testing inside of a block", env: {TEST_FOO: "original foo", TEST_BAR: "original bar"} do
      expect(configuration.foo).to eq "original foo"
      expect(configuration.bar).to eq "original bar"

      retval = configuration.override!(foo: "new foo") do
        expect(configuration.foo).to eq "new foo"
        expect(configuration.bar).to eq "original bar"
        :ok
      end

      expect(retval).to eq :ok
      expect(configuration.foo).to eq "original foo"
      expect(configuration.bar).to eq "original bar"
    end

    it "can override using the class method", env: {TEST_FOO: "original foo"} do
      configuration.class.override!(foo: "new foo") do
        expect(configuration.foo).to eq "new foo"
      end
    end

    it "casts test values to the proper type" do
      configuration.override!(int: "1") do
        expect(configuration.int).to eq 1
      end
    end

    it "uses default values if the test values are blank" do
      configuration.override!(default_int: "") do
        expect(configuration.default_int).to eq 1
      end
    end

    it "can override static values" do
      static_value = configuration.static
      configuration.override!(static: "new value") do
        expect(configuration.static).to eq "new value"
      end
      expect(configuration.static).to eq static_value
    end
  end

  describe "with hierarchy disabled" do
    it "loads values only from explicitly defined sources", {
      env: {EXPLICIT_HOST: "env.host", EXPLICIT_TIMEOUT: "4", EXPLICIT_TOKEN: "envtoken"},
      settings: {"explicit.host" => "runtime.host", "explicit.timeout" => 10, "explicit.token" => "runtimetoken"}
    } do
      config = ExplicitConfiguration.instance
      expect(config.host).to eq "yaml.host"
      expect(config.timeout).to eq 10
      expect(config.token).to eq "envtoken"
    end
  end

  describe "__to_hash__" do
    it "returns a hash of the configuration values", env: {MY_SERVICE_TOKEN: "foobar"} do
      expect(MyServiceConfiguration.instance.__to_hash__).to eq({
        "auth_token" => "securehash:7edf2d5530bce0def047b22f611ce887",
        "host" => nil,
        "port" => 80,
        "protocol" => "https",
        "timeout" => 5.0
      })
    end
  end

  describe "__source__" do
    it "returns the source of the value", env: {MY_SERVICE_TOKEN: "foobar"}, settings: {"my_service.host" => "host"} do
      expect(MyServiceConfiguration.instance.__source__(:auth_token)).to eq :env
      expect(MyServiceConfiguration.instance.__source__(:host)).to eq :settings
      expect(MyServiceConfiguration.instance.__source__(:timeout)).to eq :yaml
      expect(MyServiceConfiguration.instance.__source__(:port)).to eq :default
    end
  end

  describe "__available_sources__" do
    it "returns the possible data sources for a field", settings: {"my_service.host" => "host"} do
      config = MyServiceConfiguration.instance
      expect(config.__available_sources__(:auth_token)).to match_array [:env]
      expect(config.__available_sources__(:host)).to match_array [:env, :settings, :yaml]
      expect(config.__available_sources__(:port)).to match_array [:env, :settings, :yaml, :default]
    end
  end

  describe "__value_from_source__" do
    it "returns the value from the specified source", env: {MY_SERVICE_PORT: "4000"}, settings: {"my_service.port" => 5000}, yaml: {my_service: {port: 6000}} do
      expect(MyServiceConfiguration.instance.__value_from_source__(:port, :env)).to eq 4000
      expect(MyServiceConfiguration.instance.__value_from_source__(:port, :settings)).to eq 5000
      expect(MyServiceConfiguration.instance.__value_from_source__(:port, :default)).to eq 80
      expect(MyServiceConfiguration.instance.__value_from_source__(:port, :yaml)).to eq nil
      expect(MyServiceConfiguration.instance.__value_from_source__("timeout", :yaml)).to eq 5.0
    end
  end
end
