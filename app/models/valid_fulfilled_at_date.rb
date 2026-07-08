# frozen_string_literal: true

class ValidFulfilledAtDate

  include ActiveModel::Validations

  validate :valid_format
  validate :not_in_future, if: :to_time
  validate :recent, if: :to_time

  def self.min
    # Beginning of previous fiscal year
    SettingsHelper.fiscal_year_beginning(1.year.ago)
  end

  def self.max
    Time.current
  end

  def initialize(string)
    @string = string
  end

  def error
    errors[:base].first
  end

  def to_s
    @string
  end

  # Returns nil if the date is invalid
  def to_time
    return if @string.blank?

    date = Date.iso8601(@string.to_s)
    date.beginning_of_day + 12.hours
  rescue ArgumentError
    nil
  end
  alias presence to_time
  # `in_time_zone` allows us to set something like
  # `record.fulfilled_at = ValidFulfilledAtDate.new("YYYY-MM-DD")`
  # and ActiveRecord will treat it like a normal date/time.
  alias in_time_zone to_time

  private

  def valid_format
    return if @string.blank?
    errors.add(:base, :invalid) unless to_time
  end

  def recent
    errors.add(:base, :too_far_in_past) if to_time < self.class.min
  end

  def not_in_future
    errors.add(:base, :in_future) if to_time > self.class.max.end_of_day
  end

end
