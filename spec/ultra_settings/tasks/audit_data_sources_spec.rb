# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/ultra_settings/tasks/audit_data_sources"

RSpec.describe UltraSettings::Tasks::AuditDataSources do
  let(:runtime_settings) do
    TestRuntimeSetings.new(
      "my_service.port" => 80,
      "my_service.protocol" => "https"
    )
  end

  around do |example|
    if example.metadata[:runtime_settings]
      UltraSettings.runtime_settings = runtime_settings
      begin
        example.run
      ensure
        UltraSettings.runtime_settings = nil
      end
    else
      example.run
    end
  end

  describe ".unnecessary_env_vars" do
    it "returns environment variables that match their default values" do
      ClimateControl.modify(
        MY_SERVICE_TIMEOUT: "5.0",
        MY_SERVICE_PROTOCOL: "different"
      ) do
        result = described_class.unnecessary_env_vars

        # Should include timeout since it matches its YAML default (5.0)
        timeout_match = result.find { |item| item[0] == "MY_SERVICE_TIMEOUT" }
        expect(timeout_match).to eq(["MY_SERVICE_TIMEOUT", 5.0])

        # Should not include protocol since it differs from default
        protocol_match = result.find { |item| item[0] == "MY_SERVICE_PROTOCOL" }
        expect(protocol_match).to be_nil
      end
    end

    it "does not include secret fields" do
      ClimateControl.modify(MY_SERVICE_TOKEN: "token") do
        result = described_class.unnecessary_env_vars

        # token is secret, should not be in results
        token_match = result.find { |item| item[0] == "MY_SERVICE_TOKEN" }
        expect(token_match).to be_nil
      end
    end

    it "works when env var matches code default" do
      ClimateControl.modify(MY_SERVICE_PORT: "80") do
        result = described_class.unnecessary_env_vars

        # Should include port since it matches the code default (80)
        port_match = result.find { |item| item[0] == "MY_SERVICE_PORT" }
        expect(port_match).to eq(["MY_SERVICE_PORT", 80])
      end
    end

    it "returns empty array when no environment variables are unnecessary" do
      ClimateControl.modify(MY_SERVICE_PORT: "8080") do
        result = described_class.unnecessary_env_vars
        my_service_matches = result.select { |item| item[0].start_with?("MY_SERVICE_") }
        expect(my_service_matches).to be_empty
      end
    end
  end

  describe ".unnecessary_runtime_settings", :runtime_settings do
    it "returns runtime settings that match their default values" do
      result = described_class.unnecessary_runtime_settings

      # Should include port and protocol since they match their defaults
      port_match = result.find { |item| item[0] == "my_service.port" }
      expect(port_match).to eq(["my_service.port", 80])

      protocol_match = result.find { |item| item[0] == "my_service.protocol" }
      expect(protocol_match).to eq(["my_service.protocol", "https"])
    end

    it "does not include runtime settings that differ from defaults" do
      settings = TestRuntimeSetings.new(
        "my_service.port" => 8080
      )

      UltraSettings.runtime_settings = settings
      result = described_class.unnecessary_runtime_settings

      # Should not include port since it differs from default
      port_match = result.find { |item| item[0] == "my_service.port" }
      expect(port_match).to be_nil
    end

    it "does not include secret fields" do
      secret_settings = TestRuntimeSetings.new(
        "my_service.auth_token" => "secret_token"
      )

      UltraSettings.runtime_settings = secret_settings
      result = described_class.unnecessary_runtime_settings

      # auth_token is secret and also has runtime_setting: false
      secret_match = result.find { |item| item[0] == "my_service.auth_token" }
      expect(secret_match).to be_nil
    end

    it "returns empty array when no runtime settings are unnecessary" do
      different_settings = TestRuntimeSetings.new(
        "my_service.port" => 8080,
        "my_service.protocol" => "http"
      )

      UltraSettings.runtime_settings = different_settings
      result = described_class.unnecessary_runtime_settings
      my_service_matches = result.select { |item| item[0].start_with?("my_service.") }
      expect(my_service_matches).to be_empty
    end
  end

  describe ".env_vars_can_be_runtime_setting" do
    it "returns environment variables that differ from defaults and have runtime settings enabled" do
      ClimateControl.modify(
        MY_SERVICE_PORT: "8080"
      ) do
        result = described_class.env_vars_can_be_runtime_setting

        # Should include port since it differs from default and has runtime setting
        matching = result.find { |item| item[0] == "MY_SERVICE_PORT" }
        expect(matching).to eq([
          "MY_SERVICE_PORT",
          "my_service.port",
          8080
        ])
      end
    end

    it "does not include env vars that match their default value" do
      ClimateControl.modify(
        MY_SERVICE_PORT: "80"
      ) do
        result = described_class.env_vars_can_be_runtime_setting

        matching = result.find { |item| item[0] == "MY_SERVICE_PORT" }
        expect(matching).to be_nil
      end
    end

    it "does not include env vars without runtime setting support" do
      ClimateControl.modify(
        MY_SERVICE_TOKEN: "different_value"
      ) do
        result = described_class.env_vars_can_be_runtime_setting

        # auth_token has runtime_setting: false
        matching = result.find { |item| item[0] == "MY_SERVICE_TOKEN" }
        expect(matching).to be_nil
      end
    end

    it "does not include secret fields" do
      ClimateControl.modify(MY_SERVICE_TOKEN: "secret_value") do
        result = described_class.env_vars_can_be_runtime_setting

        secret_match = result.find { |item| item[0] == "MY_SERVICE_TOKEN" }
        expect(secret_match).to be_nil
      end
    end

    it "returns empty array when no env vars can be runtime settings" do
      # Don't set any env vars that differ from defaults
      result = described_class.env_vars_can_be_runtime_setting
      my_service_matches = result.select { |item| item[0].start_with?("MY_SERVICE_") }
      expect(my_service_matches).to be_empty
    end
  end

  describe ".env_vars_without_defaults" do
    it "returns fields that use environment variables but have no default value" do
      ClimateControl.modify(MY_SERVICE_HOST: "some_value") do
        result = described_class.env_vars_without_defaults

        matching = result.find { |item| item[2] == "MY_SERVICE_HOST" }
        # host has no code default and no YAML default in test env
        expect(matching).to eq([
          "MyServiceConfiguration",
          "host",
          "MY_SERVICE_HOST",
          nil
        ])
      end
    end

    it "does not include fields with code defaults" do
      ClimateControl.modify(MY_SERVICE_PORT: "some_value") do
        result = described_class.env_vars_without_defaults

        # port has a code default of 80
        matching = result.find { |item| item[2] == "MY_SERVICE_PORT" }
        expect(matching).to be_nil
      end
    end

    it "does not include fields with YAML defaults" do
      ClimateControl.modify(MY_SERVICE_TIMEOUT: "some_value") do
        result = described_class.env_vars_without_defaults

        # timeout has both YAML default (5.0) and code default (1.0)
        matching = result.find { |item| item[2] == "MY_SERVICE_TIMEOUT" }
        expect(matching).to be_nil
      end
    end

    it "does not include secret fields" do
      ClimateControl.modify(MY_SERVICE_TOKEN: "secret_value") do
        result = described_class.env_vars_without_defaults

        secret_match = result.find { |item| item[2] == "MY_SERVICE_TOKEN" }
        expect(secret_match).to be_nil
      end
    end
  end
end
