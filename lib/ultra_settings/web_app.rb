# frozen_string_literal: true

module UltraSettings
  class WebApp
    def initialize
      @settings_template = settings_template
      @css = application_css
      @javascript = application_js
    end

    def render_settings
      @settings_template.result(binding)
    end

    private

    def settings_template
      ERB.new(read_app_file("index.html.erb"))
    end

    def application_css
      read_app_file("application.css")
    end

    def application_js
      read_app_file("application.js")
    end

    def read_app_file(path)
      File.read(File.join(app_dir, path))
    end

    def app_dir
      File.expand_path(File.join("..", "..", "app"), __dir__)
    end
  end
end
