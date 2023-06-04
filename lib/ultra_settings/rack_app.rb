# frozen_string_literal: true

require "erb"

module UltraSettings
  class RackApp
    def initialize(app)
      @app = app
      @webapp = WebApp.new
    end

    def call(env)
      if env["PATH_INFO"] == "/"
        [200, {"Content-Type" => "text/html; charset=utf8"}, [@webapp.render_settings]]
      else
        @app.call(env)
      end
    end
  end
end
