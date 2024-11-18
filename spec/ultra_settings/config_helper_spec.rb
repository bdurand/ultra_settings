# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::ConfigHelper do
  subject(:service_class) do
    Class.new do
      extend UltraSettings::ConfigHelper
      configuration_class TestConfiguration
    end
  end
  describe "config" do
    it "should return the configuration" do
      expect(service_class.config).to be_a(TestConfiguration)
    end
  end

  describe "self.config" do
    it "should return the configuration" do
      expect(service_class.new.config).to be_a(TestConfiguration)
    end
  end
end
