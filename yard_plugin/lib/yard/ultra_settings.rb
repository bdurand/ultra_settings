# frozen_string_literal: true

require "yard"

module UltraSettings
  module YARD
    VERSION = File.read(File.expand_path("../../../VERSION", __dir__)).strip
  end
end

require_relative "ultra_settings/field_handler"
