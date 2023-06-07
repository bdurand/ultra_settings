# frozen_string_literal: true

class DisabledSourcesConfiguration < UltraSettings::Configuration
  self.environment_variables_disabled = true
  self.env_var_prefix = ""

  self.runtime_settings_disabled = true
  self.runtime_setting_prefix = ""

  self.yaml_config_disabled = true

  field :foo
  field :bar, env_var: true, runtime_setting: true, yaml_key: true
end
