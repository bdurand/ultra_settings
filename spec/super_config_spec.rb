# frozen_string_literal: true

require_relative "spec_helper"

describe SuperConfig do
  it "can add configurations to the root namespace" do
    expect(SuperConfig.test).to be_a(TestConfiguration)
    expect(SuperConfig.test2).to be_a(OtherConfiguration)
  end

  it "can globally disable the environment variable resolution"

  it "can globally disable the settings resolution"

  it "can globally disable the YAML config resolution"
end
