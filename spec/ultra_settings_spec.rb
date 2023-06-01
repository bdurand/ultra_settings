# frozen_string_literal: true

require_relative "spec_helper"

describe UltraSettings do
  it "can add configurations to the root namespace" do
    expect(UltraSettings.test).to be_a(TestConfiguration)
    expect(UltraSettings.test2).to be_a(OtherConfiguration)
  end
end
