# frozen_string_literal: true

module SuperConfig
  module Components
    def disable_environment_variables!
      @environment_variables_disabled = true
    end

    def environment_variables_disabled?
      defined?(@environment_variables_disabled) && @environment_variables_disabled
    end

    def disable_runtime_settings!
      @settings_disabled = true
    end

    def runtime_settings_disabled?
      defined?(@settings_disabled) && @settings_disabled
    end

    def disable_yaml_file!
      @yaml_disabled = true
    end

    def yaml_file_disabled?
      defined?(@yaml_disabled) && @yaml_disabled
    end
  end
end
