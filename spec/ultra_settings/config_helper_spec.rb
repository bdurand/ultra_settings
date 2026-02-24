# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe UltraSettings::ConfigHelper do
  subject(:service_class) do
    alternative_name = config_alias

    Class.new do
      extend UltraSettings::ConfigHelper

      configuration_class TestConfiguration, config_alias: alternative_name
    end
  end

  let(:config_alias) { :config }

  describe "config" do
    it "should return the configuration" do
      expect(service_class.config).to eq(TestConfiguration.instance)
    end
  end

  describe "self.config" do
    it "should return the configuration" do
      expect(service_class.new.config).to eq(TestConfiguration.instance)
    end
  end

  context "when the config alias is test_config" do
    let(:config_alias) { :test_config }

    describe "test_config" do
      it "should return the configuration" do
        expect(service_class.test_config).to eq(TestConfiguration.instance)
      end
    end

    describe "self.test_config" do
      it "should return the configuration" do
        expect(service_class.new.test_config).to eq(TestConfiguration.instance)
      end
    end
  end
end
