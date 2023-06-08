# frozen_string_literal: true

module UltraSettings
  class Railtie < Rails::Railtie
    config.before_configuration do
      UltraSettings.yaml_config_env = Rails.env
      UltraSettings.yaml_config_path = Rails.root.join("config")
    end
  end
end
