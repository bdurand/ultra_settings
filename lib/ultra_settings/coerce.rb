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
      "F", :F,
      "false", :false,
      "FALSE", :FALSE,
      "off", :off,
      "OFF", :OFF
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
          Array(value).map(&:to_s)
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

      # Cast variations of booleans (i.e. "true", "false", 1, 0, etc.) to actual boolean objects.
      #
      # @param value [Object]
      # @return [Boolean]
      def boolean(value)
        return nil if blank?(value)

        !FALSE_VALUES.include?(value)
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

      # @return [Boolean] true if the value is a numeric type or a string representing a number.
      def numeric?(value)
        value.is_a?(Numeric) || (value.is_a?(String) && value.to_s.match?(NUMERIC_REGEX))
      end

      # @return [Boolean] true if the value is nil or empty.
      def blank?(value)
        return true if value.nil?

        if value.respond_to?(:empty?)
          value.empty?
        else
          value.to_s.empty?
        end
      end

      # @return [Boolean] true if the value is not nil and not empty.
      def present?(value)
        !blank?(value)
      end
    end
  end
end
