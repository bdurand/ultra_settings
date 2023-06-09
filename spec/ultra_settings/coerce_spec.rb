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
end
