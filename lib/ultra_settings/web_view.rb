# frozen_string_literal: true

module UltraSettings
  # Helper class for rendering the settings information in an HTML page.
  class WebView
    attr_reader :css

    def initialize
      @layout_template = erb_template("layout.html.erb")
      @layout_css = read_app_file("layout.css")
      @css = read_app_file("application.css")
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
  end
end
