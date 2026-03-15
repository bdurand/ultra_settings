# frozen_string_literal: true

require "json"

module UltraSettings
  # Internationalization support for the web UI. Translations are stored as
  # JSON files in +app/locales/+ with one file per locale (e.g. +en.json+).
  #
  # Ruby templates use `#t` to look up a dotted key. JavaScript receives the
  # full translation hash inlined via a +<script>+ tag so that the same JSON
  # file drives both server-side and client-side strings.
  module I18n
    DEFAULT_LOCALE = "en"

    @cache = {}
    @mutex = Mutex.new

    class << self
      # Return the list of available locale codes derived from the JSON files
      # present in +app/locales/+.
      #
      # @return [Array<String>] locale codes, e.g. +["en"]+
      def available_locales
        load_all_locales.keys.sort
      end

      # Look up a translation by dotted key for the given locale.
      # Falls back to the default locale when the key is missing, and
      # ultimately returns the key itself if no translation is found.
      #
      # @param key [String] dotted translation key, e.g. +"page.title"+
      # @param locale [String] the locale code (default: +DEFAULT_LOCALE+)
      # @return [String] the translated string
      def t(key, locale: DEFAULT_LOCALE)
        translations = translations_for(locale)
        translations[key] || translations_for(DEFAULT_LOCALE)[key] || key
      end

      # Return the full translation hash for a locale. Used to inline
      # translations into the HTML page for JavaScript consumption.
      #
      # @param locale [String] the locale code
      # @return [Hash<String, String>] all key/value translations
      def translations_for(locale)
        load_all_locales[normalize_locale(locale)] || load_all_locales[DEFAULT_LOCALE] || {}
      end

      # Return the text direction for the given locale. Reads the +"dir"+ key
      # from the locale's translations hash, falling back to +"ltr"+ when not set.
      #
      # @param locale [String] the locale code
      # @return [String] +"ltr"+ or +"rtl"+
      def text_direction(locale = DEFAULT_LOCALE)
        dir = translations_for(locale)["dir"]
        (dir == "rtl") ? "rtl" : "ltr"
      end

      # Clear the translation cache. Called automatically in development mode.
      #
      # @return [void]
      def clear_cache!
        @mutex.synchronize { @cache = {} }
      end

      private

      # Normalize a locale string to just the language subtag if the full
      # tag is not available (e.g. "en-US" → "en").
      def normalize_locale(locale)
        locale = locale.to_s.strip.tr("_", "-").downcase
        return locale if @cache.key?(locale)

        # Try the language subtag (e.g. "en-us" → "en")
        lang = locale.split("-").first
        lang if @cache.key?(lang)
      end

      # Load every JSON file from the locales directory, keyed by filename
      # stem (e.g. "en").
      def load_all_locales
        if development_mode?
          @mutex.synchronize { @cache = {} }
        end

        return @cache unless @cache.empty?

        @mutex.synchronize do
          return @cache unless @cache.empty?

          Dir.glob(File.join(locales_dir, "*.json")).each do |path|
            code = File.basename(path, ".json").downcase
            @cache[code] = JSON.parse(File.read(path))
          rescue JSON::ParserError
            # Skip malformed locale files
          end
        end

        @cache
      end

      def locales_dir
        File.expand_path(File.join("..", "..", "app", "locales"), __dir__)
      end

      def development_mode?
        ENV.fetch("RACK_ENV", "development") == "development"
      end
    end
  end
end
