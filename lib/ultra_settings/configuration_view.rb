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
    # @param locale [String] The locale code for translations.
    def initialize(configuration, locale: UltraSettings::MiniI18n::DEFAULT_LOCALE)
      @configuration = configuration
      @locale = locale
    end

    # Render the HTML for the configuration view.
    #
    # The runtime settings cache is reloaded before rendering so that values changed
    # from the UI are displayed immediately rather than after the runtime settings
    # engine next refreshes itself.
    #
    # @param table_class [String] @deprecated CSS class for the table element (maintained for backwards compatibility).
    # @return [String] The rendered HTML.
    def render(table_class: "")
      UltraSettings.__with_runtime_settings_reloaded__ do
        # Expose configuration as a local for the ERB template without a direct
        # assignment, which would emit an unused variable warning under ruby -w.
        template_binding = binding
        template_binding.local_variable_set(:configuration, @configuration)
        html = ViewHelper.erb_template("configuration.html.erb").result(template_binding)
        html = html.html_safe if html.respond_to?(:html_safe)
        html
      end
    end

    # Convert the view to a string by rendering it.
    #
    # @return [String] The rendered HTML.
    def to_s
      render
    end

    private

    # Map an UltraSettings field type to a SuperSettings value type.
    #
    # @param type [Symbol] The UltraSettings field type.
    # @return [String] The corresponding SuperSettings value type.
    def super_settings_value_type(type)
      case type.to_sym
      when :symbol then "string"
      else type.to_s
      end
    end

    # Look up a translation key for the current locale.
    #
    # @param key [String] dotted translation key
    # @return [String]
    def t(key)
      UltraSettings::MiniI18n.t(key, locale: @locale)
    end

    def display_value(value)
      case value
      when Time
        value.iso8601
      else
        value.inspect
      end
    end

    # The text placed on the clipboard by the copy button. This is the raw value
    # rather than the inspected value shown in the UI so that, for example, copying
    # a string setting does not include the surrounding quotes.
    #
    # @param value [Object] The setting value.
    # @return [String] The text to copy.
    def copy_value(value)
      case value
      when nil
        ""
      when Time
        value.iso8601
      when Array
        value.join("\n")
      else
        value.to_s
      end
    end

    def secret_value(value)
      if value.nil?
        t("field.nil")
      else
        "••••••••••••••••"
      end
    end

    # Shorten a file path for display by making it relative to the working
    # directory or to the YAML configuration directory. The absolute path is
    # used if the file is not inside either directory.
    #
    # @param path [Pathname] The absolute file path.
    # @return [String] The path to display.
    def relative_path(path)
      paths = display_paths(Pathname.new(path).expand_path)
      display_path_roots.each do |root|
        paths.each do |file_path|
          relative = path_inside(file_path, root)
          return relative if relative
        end
      end
      paths.first.to_s
    end

    # The file path in both its literal and symlink resolved forms so that it can
    # be matched against a directory that is specified in either form.
    #
    # @param path [Pathname] The absolute file path.
    # @return [Array<Pathname>]
    def display_paths(path)
      [path, resolved_path(path.dirname)&.join(path.basename)].compact.uniq
    end

    # Directories that a displayed path can be made relative to, in order of
    # preference. Directories are listed in both their literal and symlink
    # resolved forms since a file path can be in either form.
    #
    # @return [Array<Pathname>]
    def display_path_roots
      roots = [Pathname.new(Dir.pwd)]
      config_path = UltraSettings::Configuration.yaml_config_path
      roots << Pathname.new(config_path) if config_path
      roots.flat_map { |root| [root.expand_path, resolved_path(root)] }.compact.uniq
    end

    # @param path [Pathname] The absolute file path.
    # @param root [Pathname] The absolute directory path.
    # @return [String, nil] The path relative to the directory or nil if it is not inside it.
    def path_inside(path, root)
      relative = path.relative_path_from(root).to_s.delete_prefix("./")
      return nil if relative == "." || relative.start_with?("..")

      relative
    rescue ArgumentError
      # relative_path_from raises if the paths have no common root (e.g. different drives).
      nil
    end

    # @param path [Pathname] The directory path.
    # @return [Pathname, nil] The path with symlinks resolved or nil if it does not exist.
    def resolved_path(path)
      path.realpath
    rescue SystemCallError
      nil
    end

    def source_chip_label(source)
      case source
      when :env then t("source.env")
      when :settings then t("source.setting")
      when :yaml then t("source.yaml")
      when :default then t("source.default")
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

    # True if the YAML keys for a configuration are hidden behind a toggle button.
    # They are hidden by default when the YAML file does not exist since the keys
    # are not used by the application.
    #
    # @param configuration [UltraSettings::Configuration] The configuration instance.
    # @return [Boolean]
    def hide_yaml_keys?(configuration)
      config_class = configuration.class
      file = config_class.configuration_file
      file.is_a?(Pathname) && !file.exist? && config_class.fields.any?(&:yaml_key)
    end

    # Inline script for the button that shows and hides the YAML keys. It is
    # inlined on the element so that the button also works when the configuration
    # view is embedded in a host application page that does not include the
    # bundled JavaScript.
    #
    # @return [String] JavaScript source for an onclick attribute.
    def toggle_yaml_keys_script
      <<~JAVASCRIPT.gsub(/\s+/, " ").tr('"', "'")
        var block = this.closest('.ultra-settings-block');
        if (block) {
          var hidden = block.classList.toggle('ultra-settings-yaml-hidden');
          this.setAttribute('aria-checked', hidden ? 'false' : 'true');
        }
      JAVASCRIPT
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
          document.getElementById('ultra-settings-dp-value').textContent = isSecret === 'true' ? window.__ultraSettingsI18n['detail.secret_value'] : value;
          document.getElementById('ultra-settings-dp-meta').innerHTML = window.__ultraSettingsI18n['detail.type_label'] + ' <span>' + type.toUpperCase() + '</span>' + (isSecret === 'true' ? ' \u00B7 <span style=color:var(--badge-secret-text)>' + window.__ultraSettingsI18n['detail.secret_badge'] + '</span>' : '');
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

    # Inline script for the copy button. It is inlined on the element so that the
    # button also works when the configuration view is embedded in a host
    # application page that does not include the bundled JavaScript.
    #
    # @return [String] JavaScript source for an onclick attribute.
    def copy_value_script
      <<~JAVASCRIPT.gsub(/\s+/, " ").tr('"', "'")
        var btn = this;
        var text = btn.dataset.copyValue || '';
        var flash = function() {
          btn.classList.add('copied');
          window.setTimeout(function() { btn.classList.remove('copied'); }, 1500);
        };
        var fallback = function() {
          var input = document.createElement('textarea');
          input.value = text;
          input.setAttribute('readonly', '');
          input.style.position = 'fixed';
          input.style.opacity = '0';
          document.body.appendChild(input);
          input.select();
          try { if (document.execCommand('copy')) { flash(); } } catch (e) {}
          document.body.removeChild(input);
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(flash, fallback);
        } else {
          fallback();
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

    def copy_icon(size = 13)
      <<~HTML
        <svg class="ultra-settings-copy-icon" width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="9" y="9" width="13" height="13" rx="2"/>
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
        </svg>
      HTML
    end

    def check_icon(size = 13)
      <<~HTML
        <svg class="ultra-settings-copy-check" width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"/>
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
        <svg width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" xmlns="http://www.w3.org/2000/svg">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" stroke-width="2" stroke-linejoin="round"/>
          <line x1="12" y1="10" x2="12" y2="14" stroke-width="2.5" stroke-linecap="round"/>
          <circle cx="12" cy="17" r="1" fill="currentColor"/>
        </svg>
      HTML
    end
  end
end
