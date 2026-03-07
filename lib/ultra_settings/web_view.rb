# frozen_string_literal: true

module UltraSettings
  # Helper class for rendering the settings information in an HTML page.
  class WebView
    attr_reader :layout_css

    # Initialize a new WebView with the specified color scheme.
    #
    # @param color_scheme [Symbol] The color scheme to use in the UI. This can be `:light`,
    #   `:dark`, or `:system`. The default is `:light`.
    def initialize(color_scheme: :light)
      @color_scheme = (color_scheme || :light).to_sym
      @layout_template = ViewHelper.erb_template("layout.html.erb")
      @layout_css = scheme_layout_css(@color_scheme)
    end

    # Render the complete settings page HTML.
    #
    # @param request [Rack::Request, nil] The current Rack request for access control.
    # @param locale [String] The locale code for translations.
    # @return [String] The rendered HTML page.
    def render_settings(request = nil, locale: UltraSettings::I18n::DEFAULT_LOCALE)
      @request = request
      @locale = locale
      @layout_template.result(binding)
    end

    # Get the content for the settings page.
    #
    # @return [String] The HTML content for the settings.
    def content
      UltraSettings::ApplicationView.new(
        color_scheme: @color_scheme,
        can_edit_super_settings: UltraSettings.can_edit_super_settings?(@request),
        locale: @locale || UltraSettings::I18n::DEFAULT_LOCALE
      ).render
    end

    # Look up a translation key for the current locale.
    #
    # @param key [String] dotted translation key
    # @return [String]
    def t(key)
      UltraSettings::I18n.t(key, locale: @locale || UltraSettings::I18n::DEFAULT_LOCALE)
    end

    # Return the text direction (+"ltr"+ or +"rtl"+) for the current locale.
    #
    # @return [String]
    def text_direction
      UltraSettings::I18n.text_direction(@locale || UltraSettings::I18n::DEFAULT_LOCALE)
    end

    private

    def scheme_layout_css(color_scheme)
      vars = ViewHelper.erb_template("layout_vars.css.erb").result(binding)
      css = ViewHelper.read_app_file("layout.css")
      "#{vars}\n#{css}"
    end
  end
end
