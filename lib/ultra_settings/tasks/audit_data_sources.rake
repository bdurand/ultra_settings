# frozen_string_literal: true

namespace :ultra_settings do
  desc <<~DOC
    Generates a report of environment variables used in configurations that are set to their default values.
    This report can help identify environment variables that are superfluous and can be removed. It skips any
    environment variables that are used for secrets.
  DOC
  task unnecessary_env_vars: :environment do
    require "ultra_settings/tasks/audit_data_sources"

    if Rails.respond_to?(:autoloaders) && Rails.autoloaders.respond_to?(:main)
      Rails.autoloaders.main.setup
      Rails.autoloaders.main.eager_load
    else
      Rails.application.eager_load!
    end
    env_vars_at_default = UltraSettings::Tasks::AuditDataSources.unnecessary_env_vars

    output = env_vars_at_default.collect do |env_var, value|
      "Environment variable #{env_var} is set to its default value: #{value.inspect}"
    end
    puts output
  end

  desc <<~DOC
    Generates a report of runtime settings used in configurations that are set to their default values.
    This report can help identify runtime settings that are superfluous and can be removed. It skips any
    runtime settings that are used for secrets.
  DOC
  task unnecessary_runtime_settings: :environment do
    require "ultra_settings/tasks/audit_data_sources"

    if Rails.respond_to?(:autoloaders) && Rails.autoloaders.respond_to?(:main)
      Rails.autoloaders.main.setup
      Rails.autoloaders.main.eager_load
    else
      Rails.application.eager_load!
    end
    unnecessary_runtime_settings = UltraSettings::Tasks::AuditDataSources.unnecessary_runtime_settings

    output = unnecessary_runtime_settings.collect do |runtime_setting, value|
      "Runtime setting #{runtime_setting} is set to its default value: #{value.inspect}"
    end
    puts output
  end

  desc <<~DOC
    Generates a report of environment variables used in configurations that can be converted to runtime settings.
    This report can help identify environment variables that can be removed if the corresponding runtime settings
    are set. It skips any environment variables that are used for secrets.
  DOC
  task env_vars_can_be_runtime_setting: :environment do
    require "ultra_settings/tasks/audit_data_sources"

    if Rails.respond_to?(:autoloaders) && Rails.autoloaders.respond_to?(:main)
      Rails.autoloaders.main.setup
      Rails.autoloaders.main.eager_load
    else
      Rails.application.eager_load!
    end
    env_vars_can_be_runtime = UltraSettings::Tasks::AuditDataSources.env_vars_can_be_runtime_setting

    output = env_vars_can_be_runtime.collect do |env_var, runtime_setting, value|
      "Environment variable #{env_var} can be converted to runtime setting #{runtime_setting} with value: #{value.inspect}"
    end
    puts output
  end

  desc <<~DOC
    Generates a report of environment variables used in configurations that do not have a default value.
    This report can help identify settings that could be set in YAML or with a default value rather than via
    environment variables. If these changes are made, then the environment variables could be removed.
    It skips any environment variables that are used for secrets.
  DOC
  task env_vars_without_default: :environment do
    require "ultra_settings/tasks/audit_data_sources"

    if Rails.respond_to?(:autoloaders) && Rails.autoloaders.respond_to?(:main)
      Rails.autoloaders.main.setup
      Rails.autoloaders.main.eager_load
    else
      Rails.application.eager_load!
    end
    env_vars_without_default = UltraSettings::Tasks::AuditDataSources.env_vars_without_default

    output = env_vars_without_default.collect do |config, field, env_var, value|
      "Environment variable #{env_var} used by #{config}##{field} does not have a default value (current value: #{value.inspect})"
    end
    puts output
  end
end
