# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::UninitializedRuntimeSettings do
  it "raises an error when trying to access a value" do
    expect { UltraSettings::UninitializedRuntimeSettings["foo"] }.to raise_error(UltraSettings::UninitializedRuntimeSettings::Error)
  end
end
