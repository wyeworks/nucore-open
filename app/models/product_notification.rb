# frozen_string_literal: true

class ProductNotification < ApplicationRecord
  enum :notification_type, { slot_available: "slot_available" }, default: "slot_available"

  attribute :reservation_days, default: 15

  belongs_to :facility
  has_and_belongs_to_many :products
  has_and_belongs_to_many :users

  before_save :set_users_count

  private

  def set_users_count
    return unless users.loaded?

    self.users_count = users.length
  end
end
