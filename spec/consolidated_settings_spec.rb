# frozen_string_literal: true

require_relative "spec_helper"

describe ConsolidatedSettings do
  it "can add configurations to the root namespace" do
    expect(ConsolidatedSettings.test).to be_a(TestConfiguration)
    expect(ConsolidatedSettings.test2).to be_a(OtherConfiguration)
  end

  it "can globally disable the environment variable resolution", env: {TEST_FOO: "env value"} do
    expect(ConsolidatedSettings.test.foo).to eq "env value"
    begin
      ConsolidatedSettings.environment_variables_disabled = true
      expect(ConsolidatedSettings.test.foo).to eq "foo value"
    ensure
      ConsolidatedSettings.environment_variables_disabled = false
    end
  end

  it "can globally disable the runtime settings resolution", settings: {"test.foo" => "settings value"} do
    expect(ConsolidatedSettings.test.foo).to eq "settings value"
    begin
      ConsolidatedSettings.runtime_settings_disabled = true
      expect(ConsolidatedSettings.test.foo).to eq "foo value"
    ensure
      ConsolidatedSettings.runtime_settings_disabled = false
    end
  end

  it "can globally disable the YAML config resolution" do
    expect(ConsolidatedSettings.test.foo).to eq "foo value"
    begin
      ConsolidatedSettings.yaml_config_disabled = true
      expect(ConsolidatedSettings.test.foo).to eq nil
    ensure
      ConsolidatedSettings.yaml_config_disabled = false
    end
  end
end
