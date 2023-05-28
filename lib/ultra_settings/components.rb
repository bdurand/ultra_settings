# frozen_string_literal: true

module UltraSettings
  module Components
    def environment_variables_disabled=(value)
      @environment_variables_disabled = !!value
    end

    def environment_variables_disabled?
      !!(defined?(@environment_variables_disabled) && @environment_variables_disabled)
    end

    def runtime_settings_disabled=(value)
      @runtime_settings_disabled = !!value
    end

    def runtime_settings_disabled?
      !!(defined?(@runtime_settings_disabled) && @runtime_settings_disabled)
    end

    def yaml_config_disabled=(value)
      @yaml_config_disabled = !!value
    end

    def yaml_config_disabled?
      !!(defined?(@yaml_config_disabled) && @yaml_config_disabled)
    end
  end
end
