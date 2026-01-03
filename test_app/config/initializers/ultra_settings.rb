# frozen_string_literal: true

UltraSettings.fields_secret_by_default = false

UltraSettings.runtime_settings = {
  "app.service_timeout" => 2.0
}

ENV["APP_API_KEY"] = "testkey"
ENV["APP_SERVICE_URL"] = "https://api.local"
ENV["APP_MAX_CONNECTIONS"] = "5"
ENV["APP_DEBUG_MODE"] = "true"
