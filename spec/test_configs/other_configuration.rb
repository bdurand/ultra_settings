# frozen_string_literal: true

class OtherConfiguration < UltraSettings::Configuration
  self.env_var_prefix = "OTHER_CONFIG_"
  self.runtime_setting_prefix = "other_config_"
  self.configuration_file = "other_config.yml"

  field :foo
  field :bar
  field :baz, yaml_key: "nested.baz"
end
