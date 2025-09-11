# frozen_string_literal: true

require "set"

module UltraSettings
  # Utility functions for coercing values to other data types.
  class Coerce
    # rubocop:disable Lint/BooleanSymbol
    FALSE_VALUES = Set.new([
      false, 0,
      "0", :"0",
      "f", :f,
      "false", :false,
      "off", :off
    ]).freeze
    # rubocop:enable Lint/BooleanSymbol

    NUMERIC_REGEX = /\A-?\d+(?:\.\d+)?\z/

    class << self
      # Cast a value to a specific type.
      #
      # @param value [Object]
      # @param type [Symbol]
      # @return [Object]
      def coerce_value(value, type)
        return nil if value.nil? || value == ""

        case type
        when :integer
          value.is_a?(Integer) ? value : value.to_s&.to_i
        when :float
          value.is_a?(Float) ? value : value.to_s&.to_f
        when :boolean
          boolean(value)
        when :datetime
          time(value)
        when :array
          array(value).map(&:to_s)
        when :symbol
          value.to_s.to_sym
        when :rollout
          if numeric?(value)
            value.to_f
          else
            boolean(value)
          end
        else
          value.to_s
        end
      end

      # Cast value of array
      #
      # @param value [Object]
      # @return [Array]
      def array(value)
        return [] if blank?(value)
        return value.collect(&:to_s) if value.is_a?(Array)

        parse_csv_line(value.to_s)
      end

      # Cast variations of booleans (i.e. "true", "false", 1, 0, etc.) to actual boolean objects.
      #
      # @param value [Object]
      # @return [Boolean]
      def boolean(value)
        return nil if blank?(value)
        return false if value == false

        !FALSE_VALUES.include?(value.to_s.downcase)
      end

      # Cast a value to a Time object.
      #
      # @param value [Object]
      # @return [Time]
      def time(value)
        value = nil if value.nil? || value.to_s.empty?
        return nil if value.nil?

        time = if numeric?(value)
          Time.at(value.to_f)
        elsif value.respond_to?(:to_time)
          value.to_time
        else
          Time.parse(value.to_s)
        end
        if time.respond_to?(:in_time_zone) && Time.respond_to?(:zone)
          time = time.in_time_zone(Time.zone)
        end
        time
      end

      # @param value [Object] The value to check.
      # @return [Boolean] true if the value is a numeric type or a string representing a number.
      def numeric?(value)
        value.is_a?(Numeric) || (value.is_a?(String) && value.to_s.match?(NUMERIC_REGEX))
      end

      # @param value [Object] The value to check.
      # @return [Boolean] true if the value is nil or empty.
      def blank?(value)
        return true if value.nil?

        if value.respond_to?(:empty?)
          value.empty?
        else
          value.to_s.empty?
        end
      end

      # @param value [Object] The value to check.
      # @return [Boolean] true if the value is not nil and not empty.
      def present?(value)
        !blank?(value)
      end

      private

      # Parse a line of CSV data to an array of strings. Elements are separated by commas and
      # characters can be escaped with a backslash.
      def parse_csv_line(line)
        values = []
        current_value = +""
        in_quotes = false

        i = 0
        while i < line.length
          char = line[i]

          if char == "\\"
            if i + 1 < line.length
              current_value << line[i + 1]
              i += 1
            else
              current_value << "\\"
            end
          elsif char == '"'
            in_quotes = !in_quotes
          elsif char == "," && !in_quotes
            values << current_value.strip
            current_value = +""
          else
            current_value << char
          end

          i += 1
        end

        values << current_value.strip unless current_value.empty?

        values
      end
    end
  end
end
