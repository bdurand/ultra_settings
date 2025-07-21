# frozen_string_literal: true

module UltraSettings
  # Helper class for rendering the settings information in an HTML page.
  class WebView
    attr_reader :layout_css

    # @param color_scheme [Symbol] The color scheme to use in the UI. This can be `:light`,
    #  `:dark`, or `:system`. The default is `:light`.
    def initialize(color_scheme: :light)
      @color_scheme = (color_scheme || :light).to_sym
      @layout_template = ViewHelper.erb_template("layout.html.erb")
      @layout_css = scheme_layout_css(@color_scheme)
    end

    def render_settings
      @layout_template.result(binding)
    end

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
