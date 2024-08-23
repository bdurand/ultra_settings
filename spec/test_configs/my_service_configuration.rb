class MyServiceConfiguration < UltraSettings::Configuration
  self.fields_secret_by_default = false

  field :host, type: :string

  field :port, type: :integer, default: 80

  field :protocol, type: :string, default: "https"

  field :timeout, type: :float, default: 1.0, default_if: ->(val) { val <= 0 }

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
