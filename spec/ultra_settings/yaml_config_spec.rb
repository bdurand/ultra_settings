# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::YamlConfig do
  it "returns the shared config if there is no environment config" do
    config = {
      "shared" => {
        "foo" => "bar"
      }
    }
    expect(File).to receive(:read).with("config.yml").and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo" => "bar")
  end

  it "returns the environment config if there is no shared config" do
    config = {
      "test" => {
        "foo" => "bar"
      }
    }
    expect(File).to receive(:read).with("config.yml").and_return(YAML.dump(config))
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
    expect(File).to receive(:read).with("config.yml").and_return(YAML.dump(config))
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
    expect(File).to receive(:read).with("config.yml").and_return(YAML.dump(config))
    yaml_config = UltraSettings::YamlConfig.new("config.yml", "test")
    expect(yaml_config.to_h).to eq("foo.bar" => "baz", "bar.biz" => "buz")
  end
end
