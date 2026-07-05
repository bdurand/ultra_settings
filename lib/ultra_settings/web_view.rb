# frozen_string_literal: true

module UltraSettings
  # Helper class for rendering the settings information in an HTML page.
  class WebView
    include RenderHelper

    attr_reader :layout_css

    # Initialize a new WebView with the specified color scheme.
    #
    # @param color_scheme [Symbol, nil] The color scheme to use in the UI. This can be `:light`,
    #   `:dark`, or `:system`. When `nil`, a toggle control is rendered and
    #   `[data-theme=dark]` is used as the dark mode CSS selector.
    def initialize(color_scheme: :light)
      @color_scheme = color_scheme&.to_sym
      @dark_mode_selector = @color_scheme.nil? ? "[data-theme=dark]" : nil
      @layout_template = ViewHelper.erb_template("layout.html.erb")
      @layout_css = scheme_layout_css(@color_scheme, @dark_mode_selector)
      @locale = nil
    end

    # Render the complete settings page HTML.
    #
    # This instance may be shared between concurrent requests, so per request
    # state is set on a copy of the view rather than on the shared instance.
    #
    # @param request [Rack::Request, nil] The current Rack request for access control.
    # @param locale [String] The locale code for translations.
    # @return [String] The rendered HTML page.
    def render_settings(request = nil, locale: UltraSettings::MiniI18n::DEFAULT_LOCALE)
      refresh_super_settings!
      renderer = dup
      renderer.instance_variable_set(:@locale, locale)
      renderer.render_layout
    end

    # Render the layout template in the context of this instance.
    #
    # @return [String] The rendered HTML page.
    # @api private
    def render_layout
      @layout_template.result(binding)
    end

    # Get the content for the settings page.
    #
    # @return [String] The HTML content for the settings.
    def content
      UltraSettings::ApplicationView.new(
        color_scheme: @color_scheme || :light,
        dark_mode_selector: @dark_mode_selector,
        locale: @locale || UltraSettings::MiniI18n::DEFAULT_LOCALE
      ).render
    end

    # Look up a translation key for the current locale.
    #
    # @param key [String] dotted translation key
    # @return [String]
    def t(key)
      UltraSettings::MiniI18n.t(key, locale: @locale || UltraSettings::MiniI18n::DEFAULT_LOCALE)
    end

    # Return the text direction (+"ltr"+ or +"rtl"+) for the current locale.
    #
    # @return [String]
    def text_direction
      UltraSettings::MiniI18n.text_direction(@locale || UltraSettings::MiniI18n::DEFAULT_LOCALE)
    end

    private

    def scheme_layout_css(color_scheme, dark_mode_selector)
      vars = ViewHelper.erb_template("layout_vars.css.erb").result(binding)
      css = ViewHelper.read_app_file("layout.css")
      "#{vars}\n#{css}"
    end

    def refresh_super_settings!
      return unless defined?(SuperSettings) && UltraSettings.__runtime_settings__ == SuperSettings

      SuperSettings.refresh_settings
    end
  end
end
