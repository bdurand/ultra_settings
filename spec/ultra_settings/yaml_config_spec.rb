# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::YamlConfig do
  it "returns the shared config if there is no environment config" do
    config = {
      "shared" => {
        "foo" => "bar"
      }
    }
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo" => "bar")
  end

  it "returns the environment config if there is no shared config" do
    config = {
      "test" => {
        "foo" => "bar"
      }
    }
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo" => "bar")
  end

  it "returns the environment config merged into the shared config" do
    config = {
      "shared" => {
        "foo" => "bar",
        "bar" => "baz"
      },
      "test" => {
        "bar" => "qux",
        "biz" => "buz"
      }
    }
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo" => "bar", "bar" => "qux", "biz" => "buz")
  end

  it "returns a one level deep hash" do
    config = {
      "shared" => {
        "foo" => {
          "bar" => "baz"
        }
      },
      "test" => {
        "bar" => {
          "biz" => "buz"
        }
      }
    }
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo.bar" => "baz", "bar.biz" => "buz")
  end

  it "supports YAML anchors and aliases" do
    yaml = <<~YAML
      shared: &defaults
        foo: "bar"
        bar: "baz"

      test:
        <<: *defaults
        bar: "qux"
    YAML
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(yaml)
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo" => "bar", "bar" => "qux")
  end

  it "supports unquoted date and time values" do
    yaml = <<~YAML
      test:
        starts_on: 2024-01-15
        starts_at: 2024-01-15 12:30:00 Z
    YAML
    expect(File).to receive(:read).with("config.yml", encoding: Encoding::UTF_8).and_return(yaml)
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h["starts_on"]).to eq Date.new(2024, 1, 15)
    expect(yaml_config.to_h["starts_at"]).to eq Time.utc(2024, 1, 15, 12, 30)
  end
end
