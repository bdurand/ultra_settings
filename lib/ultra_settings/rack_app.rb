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

      locale = resolve_locale(request)
      [200, {"content-type" => "text/html; charset=utf8"}, [webview.render_settings(request, locale: locale)]]
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

    # Determine the locale for a request. Precedence:
    # 1. ?lang= query parameter
    # 2. ultra_settings_locale cookie (set by the language picker)
    # 3. Accept-Language header
    # 4. Default locale
    def resolve_locale(request)
      available = UltraSettings::I18n.available_locales

      # 1. Explicit query parameter
      lang = request.params["lang"] if request.respond_to?(:params)
      return lang if lang && available.include?(lang)

      # 2. Cookie
      cookie = request.cookies["ultra_settings_locale"] if request.respond_to?(:cookies)
      return cookie if cookie && available.include?(cookie)

      # 3. Accept-Language header
      accept = request.env["HTTP_ACCEPT_LANGUAGE"] if request.respond_to?(:env)
      locale_from_accept_language(accept.to_s, available) || UltraSettings::I18n::DEFAULT_LOCALE
    end

    # Parse the Accept-Language header and return the best matching locale.
    def locale_from_accept_language(header, available)
      return nil if header.nil? || header.empty?

      # Parse tags with optional quality values, e.g. "en-US,en;q=0.9,fr;q=0.8"
      tags = header.split(",").map { |entry|
        parts = entry.strip.split(";")
        tag = parts[0].to_s.strip.downcase.tr("_", "-")
        q = 1.0
        parts[1..-1].each do |p|
          if p.strip.start_with?("q=")
            q = p.strip.sub("q=", "").to_f
          end
        end
        [tag, q]
      }.sort_by { |_, q| -q }

      tags.each do |tag, _|
        return tag if available.include?(tag)
        # Try language subtag
        lang = tag.split("-").first
        return lang if available.include?(lang)
      end

      nil
    end
  end
end
