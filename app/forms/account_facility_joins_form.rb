# frozen_string_literal: true

class AccountFacilityJoinsForm
  include ActiveModel::Model

  attr_accessor :account, :current_facility

  validates :facility_ids, presence: true
  validates :account, presence: true
  validate :must_include_current_facility

  def facility_ids
    @facility_ids || account.facilities.pluck(:id)
  end

  def facility_ids=(facility_ids)
    @facility_ids = Array(facility_ids).select(&:present?)
  end

  def save
    return unless valid?

    account.facilities = Facility.find(facility_ids)
    true
  end

  private

  def must_include_current_facility
    return if current_facility.cross_facility? || facility_ids.map(&:to_s).include?(current_facility.id.to_s)

    errors.add(:facility_ids, :missing_current_facility)
  end
end
