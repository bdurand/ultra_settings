# frozen_string_literal: true

module UltraSettings
  # Railtie to automatically configure settings for Rails applications.
  # By default this will automatically load any configuration classes in the
  # app/configurations directory. This can be customized by setting the
  # `config.ultra_settings.auto_load_directories` option.
  class Railtie < Rails::Railtie
    config.ultra_settings = ActiveSupport::OrderedOptions.new
    config.ultra_settings.auto_load_directories ||= [File.join("app", "configurations")]

    config.before_configuration do
      UltraSettings::Configuration.yaml_config_env ||= Rails.env
      UltraSettings::Configuration.yaml_config_path ||= Rails.root.join("config")
    end

    # Automatically register any configuration classes in the app/configurations
    # directory. The path to load can be customized by setting the
    # `config.ultra_settings.auto_load_directory` option.
    config.after_initialize do
      Array(Rails.application.config.ultra_settings.auto_load_directories).each do |directory|
        next unless directory

        app_config_dir = Rails.root.join(directory)
        app_config_dir.glob("**/*_configuration.rb").each do |file_path|
          relative_path = file_path.relative_path_from(app_config_dir).to_s
          class_name = relative_path.chomp(".rb").classify
          unless UltraSettings.added?(class_name)
            config_name = class_name.delete_suffix("Configuration").underscore.tr("/", "_")
            UltraSettings.add(config_name, class_name)
          end
        end
      end
    end

    rake_tasks do
      Dir.glob(File.expand_path("tasks/*.rake", __dir__)).each do |rake_file|
        load rake_file
      end
    end
  end
end
