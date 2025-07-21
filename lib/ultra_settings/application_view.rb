# frozen_string_literal: true

module UltraSettings
  # This class can render information about all configurations. It is used by the bundled
  # web UI, but you can use it to embed the configuration information in your own web pages.
  #
  # The output will be a simple HTML drop down list that can be used to display an HTML element
  # showing each configuration. You can specify the CSS class for the select element by passing
  # the `select_class` option to the `render` method. By default the select element has
  # the class `ultra-settings-select`.
  #
  # @example
  #  <h1>Application Configuration</h1>
  #  <%= UltraSettings::ApplicationView.new.render(select_class: 'form-control') %>
  class ApplicationView
    attr_reader :css

    def initialize(color_scheme: :light)
      @css = application_css(color_scheme)
      @css = @css.html_safe if @css.respond_to?(:html_safe)
    end

    def render(select_class: "ultra-settings-select", table_class: "")
      html = ViewHelper.erb_template("index.html.erb").result(binding)
      html = html.html_safe if html.respond_to?(:html_safe)
      html
    end

    def style_tag
      tag = "<style type=\"text/css\">\n#{css}\n</style>"
      tag = tag.html_safe if tag.respond_to?(:html_safe)
      tag
    end

    def to_s
      render
    end

    private

    def html_escape(value)
      ERB::Util.html_escape(value)
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
