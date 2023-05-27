# frozen_string_literal: true

class TestConfiguration < SuperConfig::Configuration
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
end
