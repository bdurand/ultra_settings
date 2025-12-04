# frozen_string_literal: true

module UltraSettings
  # Helper methods for rendering views.
  module RenderHelper
    # HTML escape a value.
    #
    # @param value [String] The value to escape.
    # @return [String] The escaped value.
    def html_escape(value)
      ERB::Util.html_escape(value)
    end

    # Render a partial template with the given locals.
    #
    # @param partial_name [String] The name of the partial template (without the leading underscore and file extension).
    # @param locals [Hash] A hash of local variables to pass to the template.
    # @return [String] The rendered HTML of the partial.
    def render_partial(partial_name, locals = {})
      template = ViewHelper.erb_template("_#{partial_name}.html.erb")
      b = binding
      locals.each do |key, value|
        b.local_variable_set(key, value)
      end
      template.result(b)
    end
  end
end
