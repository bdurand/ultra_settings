# frozen_string_literal: true

module UltraSettings
  # Helper class for rendering the settings information in an HTML page.
  class WebView
    attr_reader :css

    # @param color_scheme [Symbol] The color scheme to use in the UI. This can be `:light`,
    #  `:dark`, or `:system`. The default is `:light`.
    def initialize(color_scheme: :light)
      color_scheme = (color_scheme || :light).to_sym
      @layout_template = erb_template("layout.html.erb")
      @layout_css = layout_css(color_scheme)
      @css = application_css(color_scheme)
    end

    def render_settings
      @layout_template.result(binding)
    end

    def content
      UltraSettings::ApplicationView.new.render
    end

    private

    def erb_template(path)
      ERB.new(read_app_file(path))
    end

    def read_app_file(path)
      File.read(File.join(app_dir, path))
    end

    def app_dir
      File.expand_path(File.join("..", "..", "app"), __dir__)
    end

    def layout_css(color_scheme)
      vars = erb_template("layout_vars.css.erb").result(binding)
      css = read_app_file("layout.css")
      "#{vars}\n#{css}"
    end

    def application_css(color_scheme)
      vars = erb_template("application_vars.css.erb").result(binding)
      css = read_app_file("application.css")
      "#{vars}\n#{css}"
    end
  end
end
