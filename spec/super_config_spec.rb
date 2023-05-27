# frozen_string_literal: true

require_relative "spec_helper"

describe SuperConfig do
  it "can add configurations to the root namespace" do
    expect(SuperConfig.test).to be_a(TestConfiguration)
    expect(SuperConfig.test2).to be_a(OtherConfiguration)
  end

  it "can globally disable the environment variable resolution", env: {TEST_FOO: "env value"} do
    expect(SuperConfig.test.foo).to eq "env value"
    begin
      SuperConfig.environment_variables_disabled = true
      expect(SuperConfig.test.foo).to eq "foo value"
    ensure
      SuperConfig.environment_variables_disabled = false
    end
  end

  it "can globally disable the runtime settings resolution", settings: {"test.foo" => "settings value"} do
    expect(SuperConfig.test.foo).to eq "settings value"
    begin
      SuperConfig.runtime_settings_disabled = true
      expect(SuperConfig.test.foo).to eq "foo value"
    ensure
      SuperConfig.runtime_settings_disabled = false
    end
  end

  it "can globally disable the YAML config resolution" do
    expect(SuperConfig.test.foo).to eq "foo value"
    begin
      SuperConfig.yaml_config_disabled = true
      expect(SuperConfig.test.foo).to eq nil
    ensure
      SuperConfig.yaml_config_disabled = false
    end
  end
end
