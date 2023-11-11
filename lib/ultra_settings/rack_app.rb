# frozen_string_literal: true

module UltraSettings
  # Rack application for displaying the current settings in an HTML page.
  # No setting values are displayed, but you should still add some
  # sort of authentication if you want to use this in production.
  class RackApp
    def initialize
      @webview = nil
    end

    def call(env)
      [200, {"content-type" => "text/html; charset=utf8"}, [webview.render_settings]]
    end

    private

    def webview
      if ENV.fetch("RAILS_ENV", ENV.fetch("RACK_ENV", "development")) == "development"
        @webview = nil
      end
      @webview ||= WebView.new
    end
  end
end
