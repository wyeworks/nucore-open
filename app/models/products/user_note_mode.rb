# frozen_string_literal: true

module Products
  class UserNoteMode
    VALID_MODES = %w(hidden optional required).freeze

    attr_reader :raw_value

    # An array of UserNoteModes representing the possible modes
    # Use this in validations and form collections.
    def self.all
      VALID_MODES.map { |value| new(value) }
    end

    def self.valid?(mode)
      VALID_MODES.include?(mode)
    end

    def self.[](mode)
      if mode.is_a?(self)
        mode
      elsif valid?(mode)
        new(mode)
      else
        InvalidUserNoteMode.new(mode)
      end
    end

    # Prefer the use of the factory `UserNoteMode[raw_value]` over directly
    # initializing this class with `new` as the factory method will not raise
    # a hard error on invalid inputs.
    def initialize(raw_value)
      @raw_value = raw_value
      raise ArgumentError, "Invalid value: #{raw_value}" unless self.class.valid?(raw_value)
      freeze
    end

    def required?
      raw_value == "required"
    end

    def visible?
      raw_value != "hidden"
    end

    # to_label is a method by simple_form to generate the option name in dropdowns
    # that it tries before falling back to to_s
    def to_label
      I18n.t(raw_value, scope: "products.user_notes_field_mode", default: raw_value.titleize)
    end

    def to_s
      raw_value
    end

    def ==(other)
      to_s == other.to_s
    end

    class InvalidUserNoteMode
      def initialize(raw_value)
        @raw_value = raw_value
      end

      def to_label
        "Invalid User Note Mode: #{@raw_value}"
      end

      def to_s
        to_label
      end
    end
  end
end
