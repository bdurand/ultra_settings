# frozen_string_literal: true

namespace :ultra_settings do
  desc <<~DOC
    Generates a CSV report of environment variables used in configurations that are set to their default values.
    This report can help identify environment variables that are superfluous and can be removed. It skips any
    environment variables that are used for secrets.
  DOC
  task unnecessary_env_vars: :environment do
    require "csv"

    Rails.application.eager_load!
    env_vars_at_default = UltraSettings::Tasks::AuditDataSources.unnecessary_env_vars

    csv_string = CSV.generate do |csv|
      csv << ["EnvVar", "Value"]
      env_vars_at_default.each do |env_var, value|
        csv << [env_var, value]
      end
    end
    puts csv_string
  end

  desc <<~DOC
    Generates a CSV report of runtime settings used in configurations that are set to their default values.
    This report can help identify runtime settings that are superfluous and can be removed. It skips any
    runtime settings that are used for secrets.
  DOC
  task unnecessary_runtime_settings: :environment do
    require "csv"

    Rails.application.eager_load!
    unnecessary_runtime_settings = UltraSettings::Tasks::AuditDataSources.unnecessary_runtime_settings

    csv_string = CSV.generate do |csv|
      csv << ["RuntimeSetting", "Value"]
      unnecessary_runtime_settings.each do |runtime_setting, value|
        csv << [runtime_setting, value]
      end
    end
    puts csv_string
  end

  desc <<~DOC
    Generates a CSV report of environment variables used in configurations that can be converted to runtime settings.
    This report can help identify environment variables that can be removed if the corresponding runtime settings
    are set. It skips any environment variables that are used for secrets.
  DOC
  task env_vars_can_be_runtime_setting: :environment do
    require "csv"

    Rails.application.eager_load!
    env_vars_can_be_runtime = UltraSettings::Tasks::AuditDataSources.env_vars_can_be_runtime_setting

    csv_string = CSV.generate do |csv|
      csv << ["EnvVar", "RuntimeSetting", "Value"]
      env_vars_can_be_runtime.each do |env_var, runtime_setting, value|
        csv << [env_var, runtime_setting, value]
      end
    end
    puts csv_string
  end

  desc <<~DOC
    Generates a CSV report of environment variables used in configurations that do not have a default value.
    This report can help identify settings that could be set in YAML or with a default value rather than via
    environment variables. If these changes are made, then the environment variables could be removed.
    It skips any environment variables that are used for secrets.
  DOC
  task env_vars_no_default: :environment do
    require "csv"

    Rails.application.eager_load!
    env_vars_no_default = UltraSettings::Tasks::AuditDataSources.env_vars_no_default

    csv_string = CSV.generate do |csv|
      csv << ["Config", "Field", "EnvVar", "Value"]
      env_vars_no_default.each do |config, field, env_var, value|
        csv << [config, field, env_var, value]
      end
    end
    puts csv_string
  end
end
