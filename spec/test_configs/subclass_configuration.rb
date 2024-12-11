# frozen_string_literal: true

class SubclassConfiguration < TestConfiguration
  self.yaml_config_path = nil

  field :sub
  field :bar, type: :integer
end
