# frozen_string_literal: true

require "json"

module UltraSettings
  # Rack application for displaying the current settings in an HTML page.
  # No setting values are displayed, but you should still add some
  # sort of authentication if you want to use this in production.
  #
  # When super_settings editing is enabled, additional API endpoints are
  # exposed for fetching and saving settings through SuperSettings.
  class RackApp
    # Initialize a new Rack application for displaying settings.
    #
    # @param color_scheme [Symbol, nil] The color scheme to use in the UI (:light, :dark, or :system).
    def initialize(color_scheme: nil)
      @webview = nil
      @color_scheme = color_scheme
    end

    # Handle Rack requests and return the settings HTML page or API responses.
    #
    # @param env [Hash] The Rack environment.
    # @return [Array] A Rack response array [status, headers, body].
    def call(env)
      request = Rack::Request.new(env)
      path = env["PATH_INFO"].to_s.chomp("/")
      method = env["REQUEST_METHOD"]

      if UltraSettings.can_edit_super_settings?(request)
        if method == "GET" && path == "/super_settings/setting"
          return handle_fetch_setting(env)
        elsif method == "POST" && path == "/super_settings/setting"
          return handle_save_setting(env)
        end
      end

      [200, {"content-type" => "text/html; charset=utf8"}, [webview.render_settings(request)]]
    end

    private

    def webview
      if ENV.fetch("RAILS_ENV", ENV.fetch("RACK_ENV", "development")) == "development"
        @webview = nil
      end
      @webview ||= WebView.new(color_scheme: @color_scheme)
    end

    def handle_fetch_setting(env)
      query = parse_query(env["QUERY_STRING"])
      key = query["key"]
      return json_response(400, {error: "key parameter is required"}) if key.nil? || key.empty?

      setting = ::SuperSettings::RestAPI.show(key)
      if setting
        json_response(200, setting)
      else
        json_response(404, {error: "Setting not found"})
      end
    rescue => e
      json_response(500, {error: e.message})
    end

    def handle_save_setting(env)
      params = parse_json_body(env)
      return json_response(400, {error: "Invalid request body"}) unless params.is_a?(Hash)

      settings_params = params["settings"]
      return json_response(400, {error: "settings parameter is required"}) unless settings_params.is_a?(Array)

      result = ::SuperSettings::RestAPI.update(settings_params)
      if result[:success]
        json_response(200, result)
      else
        json_response(422, result)
      end
    rescue => e
      json_response(500, {error: e.message})
    end

    def json_response(status, body)
      [status, {"content-type" => "application/json; charset=utf-8", "cache-control" => "no-cache"}, [body.to_json]]
    end

    def parse_query(query_string)
      return {} if query_string.nil? || query_string.empty?
      URI.decode_www_form(query_string).to_h
    end

    def parse_json_body(env)
      body = env["rack.input"]&.read
      return nil if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end
  end
end
