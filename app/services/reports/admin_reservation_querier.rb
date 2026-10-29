# frozen_string_literal: true

module Reports
  class AdminReservationQuerier
    attr_reader :facility, :start_time, :end_time

    def initialize(facility:, start_time:, end_time:)
      @facility = facility
      @start_time = start_time
      @end_time = end_time
    end

    def reservations
      @reservations ||=
        Reservation
        .admin_and_offline
        .joins(:product)
        .where(products: { facility_id: facility.id })
        .where("reserve_end_at IS NULL OR reserve_end_at >= ?", start_time)
        .where("reserve_start_at <= ?", end_time)
    end
  end
end
