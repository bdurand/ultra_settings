# frozen_string_literal: true

module UltraSettings
  class RackApp
    def call(env)
      [200, {"Content-Type" => "text/html; charset=utf8"}, [webapp.render_settings]]
    end

    private

    def webapp
      if ENV.fetch("RAILS_ENV", ENV.fetch("RACK_ENV", "development")) == "development"
        @webapp = nil
      end
      @webapp ||= WebApp.new
    end
  end
end
