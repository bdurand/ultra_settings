# frozen_string_literal: true

require_relative "../spec_helper"

describe UltraSettings::Coerce do
  describe "boolean" do
    it "should translate false values" do
      expect(UltraSettings::Coerce.boolean(false)).to eq false
      expect(UltraSettings::Coerce.boolean("false")).to eq false
      expect(UltraSettings::Coerce.boolean(:FALSE)).to eq false
      expect(UltraSettings::Coerce.boolean("off")).to eq false
      expect(UltraSettings::Coerce.boolean(:OFF)).to eq false
      expect(UltraSettings::Coerce.boolean("f")).to eq false
      expect(UltraSettings::Coerce.boolean(:F)).to eq false
      expect(UltraSettings::Coerce.boolean(0)).to eq false
      expect(UltraSettings::Coerce.boolean("0")).to eq false
    end

    it "should cast true values" do
      expect(UltraSettings::Coerce.boolean(true)).to eq true
      expect(UltraSettings::Coerce.boolean("true")).to eq true
      expect(UltraSettings::Coerce.boolean(:TRUE)).to eq true
      expect(UltraSettings::Coerce.boolean("on")).to eq true
      expect(UltraSettings::Coerce.boolean(:ON)).to eq true
      expect(UltraSettings::Coerce.boolean("t")).to eq true
      expect(UltraSettings::Coerce.boolean(:T)).to eq true
      expect(UltraSettings::Coerce.boolean(1)).to eq true
      expect(UltraSettings::Coerce.boolean("1")).to eq true
    end

    it "should cast blank to nil" do
      expect(UltraSettings::Coerce.boolean(nil)).to eq nil
      expect(UltraSettings::Coerce.boolean("")).to eq nil
    end
  end

  describe "time" do
    it "should cast Time values" do
      time = Time.now
      expect(UltraSettings::Coerce.time(time)).to eq time
    end

    it "should cast Date values" do
      date = Date.today
      expect(UltraSettings::Coerce.time(date)).to eq date.to_time
    end

    it "should cast String values" do
      time = Time.at(Time.now.to_i)
      expect(UltraSettings::Coerce.time(time.to_s)).to eq time
    end

    it "should cast Numeric values" do
      time = Time.at(Time.now.to_i)
      expect(UltraSettings::Coerce.time(time.to_f)).to eq time
    end

    it "should cast blank to nil" do
      expect(UltraSettings::Coerce.time(nil)).to eq nil
      expect(UltraSettings::Coerce.time("")).to eq nil
    end
  end

  describe "numeric?" do
    it "should return true for numbers" do
      expect(UltraSettings::Coerce.numeric?(1)).to eq true
      expect(UltraSettings::Coerce.numeric?(1.1)).to eq true
      expect(UltraSettings::Coerce.numeric?("1")).to eq true
      expect(UltraSettings::Coerce.numeric?("1.1")).to eq true
    end

    it "should return false for non-numbers" do
      expect(UltraSettings::Coerce.numeric?("test")).to eq false
      expect(UltraSettings::Coerce.numeric?(true)).to eq false
      expect(UltraSettings::Coerce.numeric?(false)).to eq false
      expect(UltraSettings::Coerce.numeric?(nil)).to eq false
    end
  end

  describe "blank?" do
    it "should return true for nil" do
      value = nil
      expect(UltraSettings::Coerce.blank?(value)).to eq true
      expect(UltraSettings::Coerce.present?(value)).to eq false
    end

    it "should return true for empty strings" do
      value = ""
      expect(UltraSettings::Coerce.blank?(value)).to eq true
      expect(UltraSettings::Coerce.present?(value)).to eq false
    end

    it "should return true for empty iterables" do
      value = []
      expect(UltraSettings::Coerce.blank?(value)).to eq true
      expect(UltraSettings::Coerce.present?(value)).to eq false
    end

    it "should return false for false" do
      value = false
      expect(UltraSettings::Coerce.blank?(value)).to eq false
      expect(UltraSettings::Coerce.present?(value)).to eq true
    end

    it "should return false for other values" do
      value = "test"
      expect(UltraSettings::Coerce.blank?(value)).to eq false
      expect(UltraSettings::Coerce.present?(value)).to eq true
    end
  end

  describe "array" do
    it "should cast array" do
      array = [1, 2, 3]
      expect(UltraSettings::Coerce.array(array)).to eq array
    end

    it "should cast array values when comma separated" do
      array = "a, b, c"
      expect(UltraSettings::Coerce.array(array)).to eq %w[a b c]
    end

    it "should return an empty array when a blank string is passed in" do
      array = ""
      expect(UltraSettings::Coerce.array(array)).to eq []
    end

    it "should return an empty array when nil is passed in" do
      array = nil
      expect(UltraSettings::Coerce.array(array)).to eq []
    end
  end
end
