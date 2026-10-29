# frozen_string_literal: true

module Reservations
  class TimesPresenter < DelegateClass(Reservation)
    def to_s
      return unless present? # some reservations might not exist for the order_detail
      return super unless reserve_start_at && reserve_end_at
      range = TimeRange.new(display_start_at, display_end_at).to_s
      range += " (Canceled)" if canceled?
      range
    end

    def reserve_to_s
      TimeRange.new(reserve_start_at, reserve_end_at).to_s
    end

    def actuals_string
      if actual_start_at.blank? && actual_end_at.blank?
        "No actual times recorded"
      else
        TimeRange.new(actual_start_at, actual_end_at).to_s
      end
    end
  end
end
