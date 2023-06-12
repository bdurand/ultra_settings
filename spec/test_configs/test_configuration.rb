# frozen_string_literal: true

class TestConfiguration < UltraSettings::Configuration
  field :static, static: true

  field :foo, description: "An all purpose foo setting"
  field :bar
  field :baz

  field :symbol, type: :symbol
  field :int, type: :integer
  field :float, type: :float
  field :bool, type: :boolean
  field :time, type: :datetime
  field :array, type: :array
  field :string, type: :string

  field :default_int, type: :integer, default: "1"
  field :default_bool, type: :boolean, default: "true"
  field :default_if_proc, type: :integer, default: 1, default_if: ->(val) { val < 0 }
  field :default_if_method, type: :integer, default: 1, default_if: :negative?

  field :env_var, env_var: "SPECIFIC_ENV_VAR"
  field :setting, runtime_setting: "specific_setting"
  field :yaml_key, yaml_key: "specific_key"

  field :all_enabled, env_var: true, runtime_setting: true, yaml_key: true
  field :all_disabled, env_var: false, runtime_setting: false, yaml_key: false

  def negative?(val)
    val < 0
  end
end
