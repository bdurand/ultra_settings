# frozen_string_literal: true

module UltraSettings
  class RackApp
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
