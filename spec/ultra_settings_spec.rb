# frozen_string_literal: true

require_relative "spec_helper"

describe UltraSettings do
  it "can add configurations to the root namespace" do
    expect(UltraSettings.test).to be_a(TestConfiguration)
    expect(UltraSettings.test2).to be_a(OtherConfiguration)
  end

  it "can globally disable the environment variable resolution", env: {TEST_FOO: "env value"} do
    expect(UltraSettings.test.foo).to eq "env value"
    begin
      UltraSettings.environment_variables_disabled = true
      expect(UltraSettings.test.foo).to eq "foo value"
    ensure
      UltraSettings.environment_variables_disabled = false
    end
  end

  it "can globally disable the runtime settings resolution", settings: {"test.foo" => "settings value"} do
    expect(UltraSettings.test.foo).to eq "settings value"
    begin
      UltraSettings.runtime_settings_disabled = true
      expect(UltraSettings.test.foo).to eq "foo value"
    ensure
      UltraSettings.runtime_settings_disabled = false
    end
  end

  it "can globally disable the YAML config resolution" do
    expect(UltraSettings.test.foo).to eq "foo value"
    begin
      UltraSettings.yaml_config_disabled = true
      expect(UltraSettings.test.foo).to eq nil
    ensure
      UltraSettings.yaml_config_disabled = false
    end
  end
end
