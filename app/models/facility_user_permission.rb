# frozen_string_literal: true

class FacilityUserPermission < ApplicationRecord

  belongs_to :user
  belongs_to :facility

  PERMISSIONS = %i[
    read_access
    product_creation
    product_edition
    product_pricing
    order_management
    price_adjustment
    billing_send
    billing_journals
    instrument_management
    user_management
    assign_permissions
    account_management
    reporting
    project_management
    quoting
  ].freeze

  validates :user_id, uniqueness: { scope: :facility_id }
  validate :read_access_required_with_other_permissions

  before_validation :grant_product_edition_when_product_creation_granted

  def no_permissions?
    PERMISSIONS.none? { |perm| send(perm) }
  end

  def to_log_s
    "#{user} - #{facility.abbreviation}"
  end

  private

  def read_access_required_with_other_permissions
    return if read_access?
    return if (PERMISSIONS - [:read_access]).none? { |perm| send(perm) }

    errors.add(:read_access, "must be granted when other permissions are active")
  end

  def grant_product_edition_when_product_creation_granted
    self.product_edition = true if product_creation?
  end

end
