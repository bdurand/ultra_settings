# frozen_string_literal: true

require_relative "spec_helper"

describe UnifiedConfig do
  it "can add configurations to the root namespace" do
    expect(UnifiedConfig.test).to be_a(TestConfiguration)
    expect(UnifiedConfig.test2).to be_a(OtherConfiguration)
  end

  it "can globally disable the environment variable resolution", env: {TEST_FOO: "env value"} do
    expect(UnifiedConfig.test.foo).to eq "env value"
    begin
      UnifiedConfig.environment_variables_disabled = true
      expect(UnifiedConfig.test.foo).to eq "foo value"
    ensure
      UnifiedConfig.environment_variables_disabled = false
    end
  end

  it "can globally disable the runtime settings resolution", settings: {"test.foo" => "settings value"} do
    expect(UnifiedConfig.test.foo).to eq "settings value"
    begin
      UnifiedConfig.runtime_settings_disabled = true
      expect(UnifiedConfig.test.foo).to eq "foo value"
    ensure
      UnifiedConfig.runtime_settings_disabled = false
    end
  end

  it "can globally disable the YAML config resolution" do
    expect(UnifiedConfig.test.foo).to eq "foo value"
    begin
      UnifiedConfig.yaml_config_disabled = true
      expect(UnifiedConfig.test.foo).to eq nil
    ensure
      UnifiedConfig.yaml_config_disabled = false
    end
  end
end
