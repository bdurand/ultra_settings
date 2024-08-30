class MyServiceConfiguration < UltraSettings::Configuration
  self.fields_secret_by_default = false

  field :host, type: :string, description: "The hostname for the service"

  field :port, type: :integer, default: 80, description: "The port for the service"

  field :protocol, type: :string, default: "https", description: "The protocol for the service"

  field :timeout,
    type: :float,
    default: 1.0,
    default_if: ->(val) { val <= 0 },
    description: "Network timeout in seconds for requests to the service."

  field :auth_token,
    type: :string,
    env_var: "MY_SERVICE_TOKEN",
    runtime_setting: false,
    yaml_key: false,
    description: "Bearer token for accessing the service",
    secret: true

  def uri
    URI("#{protocol}://#{host}:#{port}")
  end
end
