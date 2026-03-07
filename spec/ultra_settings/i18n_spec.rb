# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::I18n do
  before do
    described_class.clear_cache!
  end

  describe ".available_locales" do
    it "returns an array of available locale codes" do
      locales = described_class.available_locales
      expect(locales).to be_an(Array)
      expect(locales).to include("en")
    end
  end

  describe ".t" do
    it "returns the translation for a known key" do
      expect(described_class.t("page.title")).to eq("Application Configuration")
    end

    it "returns the key itself when the translation is missing" do
      expect(described_class.t("nonexistent.key")).to eq("nonexistent.key")
    end

    it "falls back to the default locale when the requested locale is missing" do
      expect(described_class.t("page.title", locale: "zz")).to eq("Application Configuration")
    end

    it "returns translations for source labels" do
      expect(described_class.t("source.env")).to eq("ENV")
      expect(described_class.t("source.setting")).to eq("SETTING")
      expect(described_class.t("source.yaml")).to eq("YAML")
      expect(described_class.t("source.default")).to eq("DEFAULT")
    end

    it "returns translations for field labels" do
      expect(described_class.t("field.secret")).to eq("Secret")
      expect(described_class.t("field.static")).to eq("Static")
      expect(described_class.t("field.nil")).to eq("nil")
      expect(described_class.t("field.not_set")).to eq("not set")
    end

    it "returns translations for edit panel strings" do
      expect(described_class.t("edit.save")).to eq("Save")
      expect(described_class.t("edit.cancel")).to eq("Cancel")
      expect(described_class.t("edit.save_error")).to eq("Failed to save setting.")
    end
  end

  describe ".translations_for" do
    it "returns a hash of all translations for the given locale" do
      translations = described_class.translations_for("en")
      expect(translations).to be_a(Hash)
      expect(translations).to have_key("page.title")
      expect(translations["page.title"]).to eq("Application Configuration")
    end

    it "returns the default locale translations when the locale is unknown" do
      translations = described_class.translations_for("zz")
      expect(translations).to be_a(Hash)
      expect(translations).to have_key("page.title")
    end

    it "returns an empty hash when no locales are loaded and default is missing" do
      # This is a pathological case; in practice en.json always exists
      allow(Dir).to receive(:glob).and_return([])
      described_class.clear_cache!
      expect(described_class.translations_for("zz")).to eq({})
    end
  end

  describe ".clear_cache!" do
    it "clears the cached translations" do
      # Load translations
      described_class.t("page.title")
      # Clear
      described_class.clear_cache!
      # Should still work after clear (reloads)
      expect(described_class.t("page.title")).to eq("Application Configuration")
    end
  end

  describe ".text_direction" do
    it "returns 'ltr' for the English locale" do
      expect(described_class.text_direction("en")).to eq("ltr")
    end

    it "returns 'ltr' for an unknown locale" do
      expect(described_class.text_direction("zz")).to eq("ltr")
    end

    it "returns 'ltr' when no dir key is present in the translations" do
      allow(described_class).to receive(:translations_for).and_return({"page.title" => "Test"})
      expect(described_class.text_direction("en")).to eq("ltr")
    end

    it "returns 'rtl' when the dir key is 'rtl'" do
      allow(described_class).to receive(:translations_for).and_return({"dir" => "rtl"})
      expect(described_class.text_direction("ar")).to eq("rtl")
    end

    it "defaults to the DEFAULT_LOCALE when called without arguments" do
      expect(described_class.text_direction).to eq("ltr")
    end
  end
end
