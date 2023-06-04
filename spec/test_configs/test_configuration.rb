# frozen_string_literal: true

class TestConfiguration < UltraSettings::Configuration
  define :static, static: true

  define :foo
  define :bar
  define :baz

  define :symbol, type: :symbol
  define :int, type: :integer
  define :float, type: :float
  define :bool, type: :boolean
  define :time, type: :datetime
  define :array, type: :array
  define :string, type: :string

  define :default_int, type: :integer, default: "1"
  define :default_bool, type: :boolean, default: "true"

  define :env_var, env_var: "SPECIFIC_ENV_VAR"
  define :setting, setting: "specific_setting"
  define :yaml_key, yaml_key: "specific_key"

  define :all_enabled, env_var: true, setting: true, yaml_key: true
  define :all_disabled, env_var: false, setting: false, yaml_key: false
end
