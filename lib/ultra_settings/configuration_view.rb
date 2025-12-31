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
    # @param table_class [String] CSS class for the table element (maintained for backwards compatibility).
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

    def show_defined_value(label, value, secret)
      val = nil
      icon = nil
      css_class = nil

      if value.nil?
        val = "Not set"
        icon = not_set_icon
        css_class = "ultra-settings-icon-not-set"
      elsif secret
        val = secret_value(value)
        icon = lock_icon
        css_class = "ultra-settings-icon-secret"
      else
        val = display_value(value)
        icon = eye_icon
        css_class = "ultra-settings-icon-info"
      end

      <<~HTML
        <dfn class="#{css_class}" title="#{html_escape(val)}" onclick="#{html_escape(open_dialog_script)}" data-label="#{html_escape(label)}">
          #{icon}
        </dfn>
      HTML
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

    def info_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
          <path d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/>
        </svg>
      HTML
    end

    def not_set_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
          <path d="M11.354 4.646a.5.5 0 0 0-.708 0l-6 6a.5.5 0 0 0 .708.708l6-6a.5.5 0 0 0 0-.708"/>
        </svg>
      HTML
    end

    def lock_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path fill-rule="evenodd" d="M8 0a4 4 0 0 1 4 4v2.05a2.5 2.5 0 0 1 2 2.45v5a2.5 2.5 0 0 1-2.5 2.5h-7A2.5 2.5 0 0 1 2 13.5v-5a2.5 2.5 0 0 1 2-2.45V4a4 4 0 0 1 4-4m0 1a3 3 0 0 0-3 3v2h6V4a3 3 0 0 0-3-3"/>
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

    def eye_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8M1.173 8a13 13 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5s3.879 1.168 5.168 2.457A13 13 0 0 1 14.828 8q-.086.13-.195.288c-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5s-3.879-1.168-5.168-2.457A13 13 0 0 1 1.172 8z"/>
          <path d="M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5M4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0"/>
        </svg>
      HTML
    end

    def close_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708"/>
        </svg>
      HTML
    end

    def open_dialog_script
      <<~JAVASCRIPT.gsub(/\s+/, " ").tr('"', "'")
        this.closest('.ultra-settings-configuration').querySelector('.ultra-settings-dialog-title').textContent = this.dataset.label;
        this.closest('.ultra-settings-configuration').querySelector('.ultra-settings-dialog-value').textContent = this.title;
        this.closest('.ultra-settings-configuration').querySelector('.ultra-settings-dialog').showModal();
        this.closest('.ultra-settings-configuration').querySelector('.ultra-settings-dialog-close').blur();
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

    def override_indicator(overridden_by_source)
      source_names = {
        env: "environment variable",
        settings: "runtime setting",
        yaml: "configuration file",
        default: "default value"
      }
      <<~HTML
        <span class="ultra-settings-source-override" title="Overridden by #{source_names[overridden_by_source]}">
          #{warning_icon(14)}
          <span class="ultra-settings-source-override-text">Overridden by #{source_names[overridden_by_source]}</span>
        </span>
      HTML
    end

    def warning_icon(size = 16)
      <<~HTML
        <svg width="#{size}" height="#{size}" fill="currentColor" viewBox="0 0 16 16">
          <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5m.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2"/>
        </svg>
      HTML
    end
  end
end
