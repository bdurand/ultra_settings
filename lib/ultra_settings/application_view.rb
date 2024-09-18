# frozen_string_literal: true

module UltraSettings
  # This class can render information about all configurations. It is used by the bundled
  # web UI, but you can use it to embed the configuration information in your own web pages.
  #
  # The output will be a simple HTML drop down list that can be used to display an HTML table
  # showing each configuration. You can specify the CSS class for the select element and the tables
  # by passing the `select_class` and `table_class` option to the `render` method. By default the
  # select elewment have the class `ultra-settings-select` and the table will have the class
  # `ultra-settings-table`.
  #
  # @example
  #  <h1>Application Configuration</h1>
  #  <%= UltraSettings::ApplicationView.new.render(select_class: 'form-control', table_class: "table table-striped") %>
  class ApplicationView
    @template = nil

    class << self
      def template
        @template ||= ERB.new(read_app_file("index.html.erb"))
      end

      def javascript
        @javascript = read_app_file("application.js")
      end

      private

      def read_app_file(path)
        File.read(File.join(app_dir, path))
      end

      def app_dir
        File.expand_path(File.join("..", "..", "app"), __dir__)
      end
    end

    def render(select_class: "ultra-settings-select", table_class: "ultra-settings-table")
      html = self.class.template.result(binding)
      html = html.html_safe if html.respond_to?(:html_safe)
      html
    end

    def to_s
      render
    end

    private

    def html_escape(value)
      ERB::Util.html_escape(value)
    end

    def javascript
      self.class.javascript
    end
  end
end
