# frozen_string_literal: true

module UltraSettings
  # This class can render information about a configuration in a clean card-based layout. It is used by the
  # bundled web UI, but you can use it to embed the configuration information in your own web pages.
  #
  # The output will be HTML with a card-based layout for better readability. The `table_class` option is
  # still supported for backward compatibility but is no longer used in the new card layout.
  #
  # @example
  #  <h1>Service Configuration</h1>
  #  <%= UltraSettings::ConfigurationView.new(ServiceConfiguration.instance).render %>
  class ConfigurationView
    include RenderHelper

    # Initialize the configuration view with a configuration instance.
    #
    # @param configuration [UltraSettings::Configuration] The configuration instance to display.
    def initialize(configuration)
      @configuration = configuration
    end

    # Render the HTML for the configuration view.
    #
    # @param table_class [String] @deprecated CSS class for the table element (maintained for backwards compatibility).
    # @return [String] The rendered HTML.
    def render(table_class: "")
      configuration = @configuration
      html = ViewHelper.erb_template("configuration.html.erb").result(binding)
      html = html.html_safe if html.respond_to?(:html_safe)
      html
    end

    # Convert the view to a string by rendering it.
    #
    # @return [String] The rendered HTML.
    def to_s
      render
    end

    private

    def display_value(value)
      case value
      when Time
        value.iso8601
      else
        value.inspect
      end
    end

    def secret_value(value)
      if value.nil?
        "nil"
      else
        "••••••••••••••••"
      end
    end

    def relative_path(path)
      root_path = Pathname.new(Dir.pwd)
      config_path = UltraSettings::Configuration.yaml_config_path
      unless config_path.realpath.to_s.start_with?("#{root_path.realpath}#{File::SEPARATOR}")
        root_path = config_path
      end
      path.relative_path_from(root_path)
    end

    def source_chip_label(source)
      case source
      when :env then "ENV"
      when :settings then "SETTING"
      when :yaml then "YAML"
      when :default then "DEFAULT"
      else source.to_s.upcase
      end
    end

    def source_chip_class(source)
      case source
      when :env then "ultra-settings-chip-env"
      when :settings then "ultra-settings-chip-setting"
      when :yaml then "ultra-settings-chip-yaml"
      when :default then "ultra-settings-chip-default"
      else "ultra-settings-chip-default"
      end
    end

    def source_key_name(field, source)
      case source
      when :env then field.env_var
      when :settings then field.runtime_setting
      when :yaml then field.yaml_key
      when :default then nil
      end
    end

    def open_panel_script
      <<~JAVASCRIPT.gsub(/\s+/, " ").tr('"', "'")
        var el = this;
        var panel = document.getElementById('ultra-settings-detail-panel');
        if (panel) {
          var name = el.dataset.name || '';
          var value = el.dataset.value || '';
          var type = el.dataset.type || '';
          var isSecret = el.dataset.secret || 'false';
          document.getElementById('ultra-settings-dp-title').textContent = name;
          document.getElementById('ultra-settings-dp-value').textContent = isSecret === 'true' ? '\\u2022\\u2022\\u2022\\u2022\\u2022\\u2022\\u2022\\u2022 (secret)' : value;
          document.getElementById('ultra-settings-dp-meta').innerHTML = 'Type: <span>' + type.toUpperCase() + '</span>' + (isSecret === 'true' ? ' \\u00B7 <span style=color:var(--badge-secret-text)>SECRET</span>' : '');
          document.getElementById('ultra-settings-panel-bg').classList.add('open');
          panel.classList.add('open');
        } else {
          var block = el.closest('.ultra-settings-block');
          if (block) {
            var dialog = block.querySelector('.ultra-settings-dialog');
            if (dialog) {
              var title = dialog.querySelector('.ultra-settings-dialog-title');
              var val = dialog.querySelector('.ultra-settings-dialog-value');
              if (title) title.textContent = el.dataset.name || '';
              if (val) val.textContent = el.dataset.value || '';
              dialog.showModal();
            }
          }
        }
      JAVASCRIPT
    end

    def source_priority
      [:env, :settings, :yaml, :default]
    end

    def source_overridden_by(current_source, active_source)
      return nil if current_source == active_source

      current_index = source_priority.index(current_source)
      active_index = source_priority.index(active_source)

      return nil if current_index.nil? || active_index.nil?
      return nil if current_index < active_index

      active_source
    end

    def lock_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path fill-rule="evenodd" d="M8 0a4 4 0 0 1 4 4v2.05a2.5 2.5 0 0 1 2 2.45v5a2.5 2.5 0 0 1-2.5 2.5h-7A2.5 2.5 0 0 1 2 13.5v-5a2.5 2.5 0 0 1 2-2.45V4a4 4 0 0 1 4-4m0 1a3 3 0 0 0-3 3v2h6V4a3 3 0 0 0-3-3"/>
        </svg>
      HTML
    end

    def pin_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M4.146.146A.5.5 0 0 1 4.5 0h7a.5.5 0 0 1 .5.5c0 .68-.342 1.174-.646 1.479-.126.125-.25.224-.354.298v4.431l.078.048c.203.127.476.314.751.555C12.36 7.775 13 8.527 13 9.5a.5.5 0 0 1-.5.5h-4v4.5a.5.5 0 0 1-1 0V10h-4A.5.5 0 0 1 3 9.5c0-.973.64-1.725 1.17-2.189A6 6 0 0 1 5 6.708V2.277a3 3 0 0 1-.354-.298C4.342 1.674 4 1.179 4 .5a.5.5 0 0 1 .146-.354"/>
        </svg>
      HTML
    end

    def file_icon(size = 13)
      <<~HTML
        <svg width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/>
          <polyline points="13 2 13 9 20 9"/>
        </svg>
      HTML
    end

    def edit_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M15.502 1.94a.5.5 0 0 1 0 .706L14.459 3.69l-2-2L13.502.646a.5.5 0 0 1 .707 0l1.293 1.293zm-1.75 2.456-2-2L4.939 9.21a.5.5 0 0 0-.121.196l-.805 2.414a.25.25 0 0 0 .316.316l2.414-.805a.5.5 0 0 0 .196-.12l6.813-6.814z"/>
          <path fill-rule="evenodd" d="M1 13.5A1.5 1.5 0 0 0 2.5 15h11a1.5 1.5 0 0 0 1.5-1.5v-6a.5.5 0 0 0-1 0v6a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5H9a.5.5 0 0 0 0-1H2.5A1.5 1.5 0 0 0 1 2.5z"/>
        </svg>
      HTML
    end

    def close_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <line x1="18" y1="6" x2="6" y2="18"/>
          <line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
      HTML
    end

    def warning_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
          <line x1="12" y1="9" x2="12" y2="13"/>
          <line x1="12" y1="17" x2="12.01" y2="17"/>
        </svg>
      HTML
    end
  end
end
