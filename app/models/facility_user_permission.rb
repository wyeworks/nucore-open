# frozen_string_literal: true

class FacilityUserPermission < ApplicationRecord

  belongs_to :user
  belongs_to :facility

  PERMISSIONS = %i[
    product_management
    product_pricing
    order_management
    price_adjustment
    billing_send
    billing_journals
    instrument_management
    assign_permissions
  ].freeze

  validates :user_id, uniqueness: { scope: :facility_id }

  def no_permissions?
    PERMISSIONS.none? { |perm| send(perm) }
  end

  def to_log_s
    "#{user} - #{facility.abbreviation}"
  end


end
