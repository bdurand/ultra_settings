# frozen_string_literal: true

module UltraSettings
  # This class can render information about a configuration in an HTML table. It is used by the
  # bundled web UI, but you can use it to embed the configuration information in your own web pages.
  #
  # The output will be an HTML table. You can specify the CSS class for the table by passing the
  # `table_class` option to the `render` method. By default the table will have the class
  # `ultra-settings-table`.
  #
  # @example
  #  <h1>Service Configuration</h1>
  #  <%= UltraSettings::ConfigurationView.new(ServiceConfiguration.instance).render(table_class: "table table-striped") %>
  class ConfigurationView
    @template = nil

    class << self
      def template
        @template ||= ERB.new(read_app_file("configuration.html.erb"))
      end

      private

      def read_app_file(path)
        File.read(File.join(app_dir, path))
      end

      def app_dir
        File.expand_path(File.join("..", "..", "app"), __dir__)
      end
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def render(table_class: "ultra-settings-table")
      configuration = @configuration
      html = self.class.template.result(binding)
      html.html_safe if html.respond_to?(:html_safe)
      html
    end

    def to_s
      render
    end

    private

    def html_escape(value)
      ERB::Util.html_escape(value)
    end

    def display_value(value)
      case value
      when Time
        value.iso8601
      else
        value.inspect
      end
    end

    def set_via(label, value, configuration, field, option)
      html = html_escape(label)
      html = "#{html}: <code class=\"ultra-settings-set-via\">#{html_escape(value)}</code>" unless value.nil?
      if configuration.__source__(field.name) == option
        html = "<strong class=\"ultra-settings-set-via-selected\">#{html}</strong>"
      end
      html
    end

    def secret_value(value)
      if value.nil?
        "nil"
      else
        "••••••••••••••••"
      end
    end

    def relative_path(path)
      path.relative_path_from(UltraSettings::Configuration.yaml_config_path)
    end
  end
end
