# frozen_string_literal: true

class ExplicitConfiguration < UltraSettings::Configuration
  self.environment_variables_disabled = true
  self.runtime_settings_disabled = true
  self.yaml_config_disabled = true

  field :host, yaml_key: "host"
  field :token, env_var: "EXPLICIT_TOKEN"
  field :timeout, type: :integer, runtime_setting: "explicit.timeout", default: 5
end
