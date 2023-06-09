# frozen_string_literal: true

module Test
  class NamespaceConfiguration < UltraSettings::Configuration
    self.env_var_delimiter = "__"
    self.env_var_upcase = false

    self.runtime_setting_delimiter = "->"
    self.runtime_setting_upcase = true

    self.yaml_config_path = File.join(__dir__, "..", "config", "my_settings", "")

    field :foo
  end
end
