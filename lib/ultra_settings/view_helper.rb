# frozen_string_literal: true

module UltraSettings
  # Base class for rendering views.
  module ViewHelper
    @cache = {}

    class << self
      def erb_template(path)
        @cache["erb:#{path}"] ||= ERB.new(read_app_file(path))
      end

      def read_app_file(path)
        @cache["file:#{path}"] ||= File.read(File.join(app_dir, path))
      end

      def app_dir
        File.expand_path(File.join("..", "..", "app"), __dir__)
      end
    end
  end
end
