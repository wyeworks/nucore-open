# frozen_string_literal: true

module Reports

  class InstrumentUnavailableReport

    QUANTITY_INDEX = 3
    HOURS_INDEX = 4

    attr_reader :facility, :start_time, :end_time

    include FacilityReservationsHelper

    def initialize(facility, date_start, date_end)
      @facility = facility
      @start_time = date_start.beginning_of_day
      @end_time = date_end.end_of_day
    end

    def numeric_columns
      [QUANTITY_INDEX, HOURS_INDEX]
    end

    def rows
      @rows ||= grouped_query.map do |key, reservations|
        key +
          [
            reservations.count,
            as_hours(reservations_total_seconds(reservations)),
          ]
      end
    end

    def total_hours
      format("%.2f", rows.map { |row| BigDecimal(row[HOURS_INDEX]) }.sum)
    end

    def total_quantity
      rows.map { |row| row[QUANTITY_INDEX] }.sum
    end

    private

    def as_hours(seconds)
      format("%.2f", seconds / 3600.0)
    end

    def grouped_query
      @grouped_query ||= query.group_by do |res|
        [
          res.product.name,
          res.type.to_s.sub(/Reservation\z/, ""),
          reservation_category_label(res),
        ]
      end
    end

    def reservations_total_seconds(reservations)
      reservations.inject(0) do |sum, r|
        sum + row_duration_in_seconds(r)
      end
    end

    def row_duration_in_seconds(row)
      ReservationRowDurationCalculator
        .new(row, start_time: start_time, end_time: end_time)
        .duration_in_seconds
    end

    def query
      querier.reservations
    end

    def querier
      @querier ||=
        AdminReservationQuerier.new(facility: facility,
                                    start_time: start_time,
                                    end_time: end_time)
    end

  end

end
