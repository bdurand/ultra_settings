# frozen_string_literal: true

module SuperConfig
  class NonStaticValueError < StandardError
    def initialize(klass, name)
      super("The value for #{klass.name}.#{name} cannot be reference during initialization")
    end
  end
end
