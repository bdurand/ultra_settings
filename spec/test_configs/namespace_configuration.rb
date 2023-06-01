# frozen_string_literal: true

module Test
  class NamespaceConfiguration < TestConfiguration
    self.env_var_delimiter = "__"
    self.env_var_upcase = false

    self.setting_delimiter = "->"
    self.setting_upcase = true

    self.yaml_config_directory = "my_settings"

    define :foo
  end
end
