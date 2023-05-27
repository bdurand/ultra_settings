# frozen_string_literal: true

class TestConfiguration < UnifiedConfig::Configuration
  define :static, static: true

  define :foo
  define :bar
  define :baz

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
end
