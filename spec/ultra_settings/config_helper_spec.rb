# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::ConfigHelper do
  subject(:service_class) do
    Class.new do
      extend UltraSettings::ConfigHelper

      configuration_class TestConfiguration
    end
  end

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
end
