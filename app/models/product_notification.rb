# frozen_string_literal: true

class ProductNotification < ApplicationRecord
  belongs_to :product

  enum :notification_type, { slot_available: :slot_available }
  enum :recipient_source, { access_list: :access_list, reservations: :reservations }

  store :data, accessors: %i[recipients reservation_days], coder: JSON

  validates_uniqueness_of :notification_type, scope: :product_id
end
