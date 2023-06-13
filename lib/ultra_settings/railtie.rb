# frozen_string_literal: true

module UltraSettings
  class Railtie < Rails::Railtie
    config.before_configuration do
      UltraSettings.yaml_config_env = Rails.env
      UltraSettings.yaml_config_path = Rails.root.join("config")
    end

    config.after_initialize do
      # TODO: check if config has not been disabled. Then load load
      # all classes found in app/configurations directory. Should also
      # allow for a custom directory to be specified.
      #
      # app_config_dir = File.expand_path('../app/configurations', __dir__)
      # Dir.glob("#{app_config_dir}/**/*.rb").each do |file_path|
      #   config_name = File.basename(file_path, '.rb')
      #   class_name = file_path[(app_config_dir.length + 1)..-4].classify
      #   UltraSettings.add(config_name, class_name)
      # end
    end
  end
end
