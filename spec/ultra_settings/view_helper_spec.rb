# frozen_string_literal: true

require "spec_helper"

RSpec.describe UltraSettings::ViewHelper do
  describe ".erb_template" do
    it "caches templates outside of development mode" do
      ClimateControl.modify(RAILS_ENV: "production", RACK_ENV: nil) do
        template = described_class.erb_template("layout.html.erb")
        expect(described_class.erb_template("layout.html.erb")).to equal(template)
      end
    end

    it "treats RAILS_ENV=production as production even when RACK_ENV is not set" do
      ClimateControl.modify(RAILS_ENV: "production", RACK_ENV: nil) do
        expect(described_class.send(:development_mode?)).to be false
      end
    end

    it "reloads templates in development mode" do
      ClimateControl.modify(RAILS_ENV: nil, RACK_ENV: nil, APP_ENV: nil) do
        template = described_class.erb_template("layout.html.erb")
        expect(described_class.erb_template("layout.html.erb")).not_to equal(template)
      end
    end
  end

  describe ".read_app_file" do
    it "reads files as UTF-8 regardless of the default external encoding" do
      css = described_class.read_app_file("application.css")
      expect(css.encoding).to eq Encoding::UTF_8
      expect(css.valid_encoding?).to be true
    end
  end
end
