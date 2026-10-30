# frozen_string_literal: true

module SplitAccounts
  class RemainderApplier
    attr_reader :original, :split_objects, :splits

    # split_objects and splits must have the same order
    def initialize(original, split_objects, splits)
      raise ArgumentError, "There should be the same number of split objects as splits" if splits.size != split_objects.size

      @original = original
      @split_objects = split_objects
      @splits = splits
    end

    def apply_remainders(attributes)
      Array(attributes).each do |attribute|
        apply_remainder(attribute)
      end
    end

    def apply_remainder(attribute)
      total_value = original.try(attribute)
      return if total_value.blank?

      remainder = total_value - floored_total(attribute)

      new_value = object_to_receive_remainder.public_send(attribute) + remainder
      object_to_receive_remainder.public_send("#{attribute}=", new_value)
    end

    private

    def object_to_receive_remainder
      split_objects[remainder_index]
    end

    def remainder_index
      @remainder_index ||= splits.find_index(&:apply_remainder?)
    end

    def floored_total(attribute)
      split_objects.reduce(BigDecimal(0)) do |sum, item|
        sum + item.public_send(attribute)
      end
    end
  end
end
