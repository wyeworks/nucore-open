# frozen_string_literal: true

module SecureRooms

  module OrderDetailExtension

    extend ActiveSupport::Concern

    included do
      has_one :occupancy, dependent: :destroy, inverse_of: :order_detail, class_name: "SecureRooms::Occupancy"

      accepts_nested_attributes_for :occupancy, update_only: true

      scope :occupancies, -> { for_product_type("SecureRoom") }
    end

  end

end
