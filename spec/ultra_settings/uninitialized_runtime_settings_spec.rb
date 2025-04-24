# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::UninitializedRuntimeSettings do
  it "raises an error when trying to access a value" do
    expect { UltraSettings::UninitializedRuntimeSettings["foo"] }.to raise_error(UltraSettings::UninitializedRuntimeSettings::Error)
  end
end
