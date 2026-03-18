# frozen_string_literal: true

module UltraSettings
  # This class can render information about all configurations. It is used by the bundled
  # web UI, but you can use it to embed the configuration information in your own web pages.
  #
  # The output will be a simple HTML drop down menu that can be used to select the configuration
  # you want to see.
  #
  # @example
  #  <h1>Application Configuration</h1>
  #  <%= UltraSettings::ApplicationView.new.render %>
  class ApplicationView
    include RenderHelper

    attr_reader :css

    # Initialize the application view with a color scheme.
    #
    # @param color_scheme [Symbol] The color scheme to use (:light, :dark, or :system).
    # @param locale [String] The locale code for translations.
    def initialize(color_scheme: :light, locale: UltraSettings::MiniI18n::DEFAULT_LOCALE)
      @css = application_css(color_scheme)
      @css = @css.html_safe if @css.respond_to?(:html_safe)
      @locale = locale
    end

    # Render the HTML for the configuration settings UI.
    #
    # @param select_class [String] @deprecated; no longer used.
    # @param table_class [String] @deprecated; no longer used.
    # @return [String] The rendered HTML.
    def render(select_class: nil, table_class: nil)
      locale = @locale # used by ERB template via binding
      html = ViewHelper.erb_template("index.html.erb").result(binding)
      html = html.html_safe if html.respond_to?(:html_safe)
      html
    end

    # Generate an HTML style tag with the CSS for the view.
    #
    # @return [String] The HTML style tag with CSS.
    def style_tag
      tag = "<style type=\"text/css\">\n#{css}\n</style>"
      tag = tag.html_safe if tag.respond_to?(:html_safe)
      tag
    end

    # Convert the view to a string by rendering it.
    #
    # @return [String] The rendered HTML.
    def to_s
      render
    end

    private

    # Look up a translation key for the current locale.
    #
    # @param key [String] dotted translation key
    # @return [String]
    def t(key)
      UltraSettings::MiniI18n.t(key, locale: @locale)
    end

    # Return the full translations hash as JSON for inlining into the page.
    #
    # @return [String] JSON string
    def translations_json
      UltraSettings::MiniI18n.translations_for(@locale).to_json
    end

    def javascript
      ViewHelper.read_app_file("application.js")
    end

    def application_css(color_scheme)
      vars = ViewHelper.erb_template("application_vars.css.erb").result(binding).strip
      css = ViewHelper.read_app_file("application.css").strip
      "#{vars}\n#{css}"
    end
  end
end
