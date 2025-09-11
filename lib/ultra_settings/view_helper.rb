# frozen_string_literal: true

module UltraSettings
  # Base class for rendering views.
  module ViewHelper
    @cache = {}

    class << self
      # Get an ERB template for rendering.
      #
      # @param path [String] The path to the template file.
      # @return [ERB] The compiled ERB template.
      def erb_template(path)
        @cache["erb:#{path}"] ||= ERB.new(read_app_file(path))
      end

      # Read a file from the app directory.
      #
      # @param path [String] The path to the file relative to the app directory.
      # @return [String] The contents of the file.
      def read_app_file(path)
        @cache["file:#{path}"] ||= File.read(File.join(app_dir, path))
      end

      # Get the app directory path.
      #
      # @return [String] The absolute path to the app directory.
      def app_dir
        File.expand_path(File.join("..", "..", "app"), __dir__)
      end
    end
  end
end
