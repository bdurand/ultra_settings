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
    # @return [String] The rendered HTML page.
    def render_settings
      @layout_template.result(binding)
    end

    # Get the content for the settings page.
    #
    # @return [String] The HTML content for the settings.
    def content
      UltraSettings::ApplicationView.new(color_scheme: @color_scheme).render
    end

    private

    def scheme_layout_css(color_scheme)
      vars = ViewHelper.erb_template("layout_vars.css.erb").result(binding)
      css = ViewHelper.read_app_file("layout.css")
      "#{vars}\n#{css}"
    end
  end
end
