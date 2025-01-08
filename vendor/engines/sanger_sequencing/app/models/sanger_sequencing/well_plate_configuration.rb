# frozen_string_literal: true

module SangerSequencing

  class WellPlateConfiguration

    def initialize(order:, reserved_cells: [])
      @reserved_cells = reserved_cells
      @order = order
    end

    CONFIGS = ActiveSupport::HashWithIndifferentAccess.new(
      default: new(reserved_cells: %w(A01 A02), order: :alternate),
      fragment: new(reserved_cells: [], order: :alternate),
      seq: new(reserved_cells: [], order: :sequential)
    ).freeze

    def self.find(key)
      CONFIGS[key] || CONFIGS[:default]
    end

    def as_json(_options = {})
      {
        reserved_cells: @reserved_cells.to_a,
        order: @order,
      }
    end

  end

end
