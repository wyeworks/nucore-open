# frozen_string_literal: true

class AdminReservation < Reservation

  CATEGORIES = %w(
    maintenance
    training
    reserved_for_staff
    instrument_unavailable
    other
  ).freeze

  belongs_to :product

  validates :category,
            inclusion: { in: CATEGORIES, allow_blank: true }
  validates :expires_mins_before, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def display_user
    created_by
  end

  # TODO: Move admin parts of Reservation here

  def admin?
    true
  end

  def expires?
    expires_mins_before.present?
  end

  private

  def set_billable_minutes
    self.billable_minutes = nil
  end

end
