# frozen_string_literal: true

module UltraSettings
  # Base class for rendering views.
  module ViewHelper
    @cache = {}
    @mutex = Mutex.new

    class << self
      # Get an ERB template for rendering.
      #
      # @param path [String] The path to the template file.
      # @return [ERB] The compiled ERB template.
      def erb_template(path)
        fetch("erb:#{path}") { ERB.new(read_app_file(path)) }
      end

      # Read a file from the app directory.
      #
      # @param path [String] The path to the file relative to the app directory.
      # @return [String] The contents of the file.
      def read_app_file(path)
        fetch("file:#{path}") { File.read(File.join(app_dir, path), encoding: Encoding::UTF_8) }
      end

      # Get the app directory path.
      #
      # @return [String] The absolute path to the app directory.
      def app_dir
        File.expand_path(File.join("..", "..", "app"), __dir__)
      end

      private

      # Fetch a value from the cache, generating it with the block if needed.
      # The value is generated outside of the lock since the block may itself
      # fetch other cached values. The cache hash is never mutated in place; a
      # copy is published with a single assignment so concurrent readers always
      # see a consistent hash. Two threads may generate the same value
      # concurrently; the first one to publish wins.
      def fetch(key, &block)
        return yield if development_mode?

        cached = @cache
        return cached[key] if cached.include?(key)

        value = yield
        @mutex.synchronize do
          if @cache.include?(key)
            @cache[key]
          else
            @cache = @cache.merge(key => value)
            value
          end
        end
      end

      def development_mode?
        UltraSettings.__development_mode__?
      end
    end
  end
end
