# frozen_string_literal: true

module UltraSettings
  class WebView
    attr_reader :css

    def initialize
      @index_template = erb_template("index.html.erb")
      @layout_template = erb_template("layout.html.erb")
      @layout_css = read_app_file("layout.css")
      @css = read_app_file("application.css")
      @javascript = read_app_file("application.js")
    end

    def render_settings
      @layout_template.result(binding)
    end

    def content
      @index_template.result(binding)
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
