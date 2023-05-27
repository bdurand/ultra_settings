# frozen_string_literal: true

class OtherConfiguration < UnifiedConfig::Configuration
  self.env_var_prefix = "OTHER_CONFIG_"
  self.setting_prefix = "other_config_"
  self.configuration_file = "config/other_config.yml"

  define :foo
  define :bar
end
