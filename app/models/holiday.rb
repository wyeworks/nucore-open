# frozen_string_literal: true

class Holiday < ApplicationRecord

  validates_presence_of :date

  scope :future, -> { where(date: Time.current.to_date..Float::INFINITY) }
  scope :on, -> (date) { where(date: date..date.end_of_day) }

  def self.allow_access?(user, product, start_date)
    return true if user.blank?
    return true if product.blank?
    return true if !product.restrict_holiday_access?
    return true if start_date.blank?
    return true if self.on(start_date.to_date).blank?
    return true if user.can_override_restrictions?(product)
    return true if product.access_group_for_user(user)&.allow_holiday_access

    false
  end

end
