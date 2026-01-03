# frozen_string_literal: true

# YARD plugin handler for the UltraSettings::Configuration.field method.
# This handler automatically generates YARD documentation for fields defined
# using the field DSL method.
module UltraSettings
  module YARD
    class FieldHandler < ::YARD::Handlers::Ruby::Base
      handles :command

      def process
        method_name = begin
          statement.method_name(true)
        rescue
          nil
        end

        return unless method_name.to_s == "field"

        # Check if we're inside a class by looking at the namespace
        return unless namespace.is_a?(::YARD::CodeObjects::ClassObject)

        # Only process field methods in UltraSettings::Configuration subclasses
        return unless inherits_from_configuration?(namespace)

        # Extract field parameters
        params = extract_field_params

        return unless params[:name]

        # Generate method documentation
        method_name = params[:name].to_s
        method_name = "#{method_name}?" if params[:type] == :boolean

        # Register the method using the proper API
        method_object = ::YARD::CodeObjects::MethodObject.new(namespace, method_name, :instance)
        register(method_object)

        method_object.signature = "def #{method_name}"
        method_object.explicit = false
        method_object.scope = :instance

        # Add description if provided
        if params[:description] && !params[:description].empty?
          method_object.docstring = format_description(params[:description])
        end

        # Add return type tag
        return_type = yard_type_for_field(params)
        method_object.docstring.add_tag(::YARD::Tags::Tag.new(:return, "", return_type))
      end

      private

      def extract_field_params
        params = {}

        # Get parameters - skip first element which is the wrapper
        param_list = statement.parameters
        return params if param_list.nil? || param_list.empty?

        # First parameter is the field name
        first_param = param_list[0]
        params[:name] = extract_symbol(first_param)

        # Process remaining parameters for keyword arguments
        param_list[1..-1].each do |param|
          next unless param
          next unless param.respond_to?(:type)

          if param.type == :assoc
            process_assoc(param, params)
          elsif param.type == :list
            # Handle list of associations
            items = param.children || []
            items.each do |item|
              process_assoc(item, params) if item.respond_to?(:type) && item.type == :assoc
            end
          end
        end

        params
      end

      def process_assoc(assoc, params)
        return unless assoc&.type == :assoc
        return unless assoc.respond_to?(:[])

        key_node = assoc[0]
        value_node = assoc[1]

        key = extract_label(key_node)
        return unless key

        case key
        when :type
          params[:type] = extract_symbol(value_node)
        when :description
          params[:description] = extract_string(value_node)
        when :default
          params[:default] = extract_value(value_node)
        when :default_if
          params[:default_if] = extract_value(value_node)
        end
      end

      def extract_label(node)
        return nil unless node

        if node.type == :label
          # Remove trailing colon from label
          node.source.to_s.sub(/:$/, "").to_sym
        elsif node.type == :symbol_literal
          extract_symbol(node)
        end
      end

      def extract_symbol(node)
        return nil unless node

        if node.type == :symbol_literal
          # Navigate through symbol_literal -> symbol -> ident structure
          symbol_node = node[0]
          if symbol_node&.type == :symbol
            ident_node = symbol_node[0]
            if ident_node&.type == :ident
              return ident_node.source.to_s.to_sym
            end
          end
        elsif node.type == :ident
          return node.source.to_s.to_sym
        end

        nil
      end

      def extract_string(node)
        return nil unless node

        # Handle case where node might already be a string (shouldn't happen but be defensive)
        return node if node.is_a?(String)
        return "" unless node.respond_to?(:type)

        if node.type == :string_literal
          # Get the content, handling string_content nodes
          if node[0]&.type == :string_content
            content_node = node[0]
            first_child = content_node[0]

            # Check if first child is a tstring_content node or a plain string (for empty strings)
            if first_child.is_a?(String)
              return first_child
            elsif first_child.respond_to?(:type) && first_child.type == :tstring_content
              return first_child.source.to_s
            end

            # Empty string with no content
            return ""
          end
          # Fallback: remove quotes
          return node.source.to_s.gsub(/^["']|["']$/, "")
        end

        nil
      end

      def extract_value(node)
        return nil unless node

        case node.type
        when :string_literal
          extract_string(node)
        when :symbol_literal
          extract_symbol(node)
        when :int
          node.source.to_i
        when :float
          node.source.to_f
        when :var_ref
          # Handle true, false, nil
          case node.source.to_s
          when "true"
            true
          when "false"
            false
          when "nil"
            nil
          else
            :unknown
          end
        when :lambda, :brace_block
          # Proc/lambda present
          :proc
        else
          # For complex expressions, indicate presence
          :present
        end
      end

      def format_description(description)
        # Handle multiline descriptions by ensuring proper formatting
        # Remove leading/trailing whitespace but preserve internal line breaks
        lines = description.strip.split("\n")
        lines.map(&:strip).join("\n")
      end

      def yard_type_for_field(params)
        base_type = case params[:type]
        when :string, "string"
          "String"
        when :symbol, "symbol"
          "Symbol"
        when :integer, "integer"
          "Integer"
        when :float, "float"
          "Float"
        when :boolean, "boolean"
          "Boolean"
        when :datetime, "datetime"
          "Time"
        when :array, "array"
          "Array<String>"
        else
          "String" # Default type
        end

        # Boolean fields always return a value (true or false), never nil
        # Fields with explicit non-nil defaults never return nil UNLESS they have a default_if condition
        has_default = params[:default] && params[:default] != :present && !params[:default].nil?
        has_default_if = params[:default_if] && params[:default_if] != :unknown

        if params[:type] == :boolean || (has_default && !has_default_if)
          base_type
        else
          "#{base_type}, nil"
        end
      end

      # Check if a class inherits from UltraSettings::Configuration
      def inherits_from_configuration?(klass)
        return false unless klass.is_a?(::YARD::CodeObjects::ClassObject)
        return true if klass.path == "UltraSettings::Configuration"

        # Check superclass
        if klass.superclass.is_a?(::YARD::CodeObjects::ClassObject)
          return inherits_from_configuration?(klass.superclass)
        elsif klass.superclass.is_a?(::YARD::CodeObjects::Proxy)
          # If superclass is a proxy, check by path
          return true if klass.superclass.path == "UltraSettings::Configuration"
        end

        false
      end
    end
  end
end
