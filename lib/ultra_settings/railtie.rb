# frozen_string_literal: true

module UltraSettings
  class Railtie < Rails::Railtie
    config.ultra_settings = ActiveSupport::OrderedOptions.new
    config.ultra_settings.auto_load_directory = File.join("app", "configurations")

    config.before_configuration do
      UltraSettings.yaml_config_env = Rails.env
      UltraSettings.yaml_config_path = Rails.root.join("config")
    end

    # Automatically register any configuration classes in the app/configurations
    # directory. The path to load can be customized by setting the
    # `config.ultra_settings.auto_load_directory` option.
    config.after_initialize do
      if Rails.application.config.ultra_settings.auto_load
        app_config_dir = Rails.root.join(config.ultra_settings.auto_load_directory)
        app_config_dir.glob("**/*.rb").each do |file_path|
          config_name = file_path.basename(".rb")
          class_name = file_path.relative_path_from(app_config_dir).to_s.chomp(".rb").classify
          UltraSettings.add(config_name, class_name)
        end
      end
    end
  end
end
