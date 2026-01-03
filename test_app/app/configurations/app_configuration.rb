# frozen_string_literal: true

class AppConfiguration < UltraSettings::Configuration
  description "Application configuration for the test app."

  field :max_connections,
    type: :integer,
    default: 5,
    description: "Maximum number of concurrent connections."

  field :service_url,
    type: :string,
    description: "URL for the external service."

  field :service_timeout,
    type: :float,
    default: 2.0,
    description: "Timeout for service requests in seconds."

  field :api_key,
    type: :string,
    secret: true,
    description: "API key for external service integration."

  field :debug_mode,
    type: :boolean,
    default: true,
    runtime_setting: false,
    description: "Enable or disable debug mode."
end
