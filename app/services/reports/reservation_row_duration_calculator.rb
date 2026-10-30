# frozen_string_literal: true

module Reports
  class ReservationRowDurationCalculator
    attr_reader :row, :start_time, :end_time

    def initialize(row, start_time:, end_time:)
      @row = row
      @start_time = start_time
      @end_time = end_time
    end

    # If a reservation begins and ends within the bounds of the report, then
    # the duration should be the same as the reservation duration.
    #
    # But if a reservation began before the report start, or ends after the
    # report end, or has not ended, this should only count the part of the
    # reservation that falls within the report bounds.
    #
    # Examples with a report range of Jan 1 to 3 (259,200 seconds, or 3 days):
    #
    # * A reservation that began December 31 at noon and has not ended
    #   - The duration is 259,200 seconds (the entire report range; 3 days)
    #
    # * A reservation that began December 31 at noon and ended Jan 1 at noon
    #   - The duration is 43,200 seconds (Jan 1 midnight to noon; 12 hours)
    #
    # * A reservation that began Jan 2 at noon and has not ended
    #   - The duration is 129,600 seconds (Jan 1 noon to EOD Jan 3; 36 hours)
    #
    # * A reservation that began Jan 2 at noon and ended Jan 2 at 1:00 pm
    #   - The duration is 3600 seconds (1 hour)
    def duration_in_seconds
      reserve_end_at = row.reserve_end_at || end_time
      reserve_end_at = end_time if reserve_end_at > end_time
      reserve_start_at = row.reserve_start_at > start_time ? row.reserve_start_at : start_time
      (reserve_end_at - reserve_start_at).round
    end
  end
end
