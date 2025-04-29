# frozen_string_literal: true

require "csv"

module Reports

  class InstrumentUnavailableExportRaw

    attr_reader :facility, :date_start, :date_end

    include CsvExporter
    include FacilityReservationsHelper

    def initialize(facility:, date_start:, date_end:)
      @facility = facility
      @date_start = date_start
      @date_end = date_end
    end

    def description
      "#{facility.name} Instrument Down Export Raw, #{formatted_date_range}"
    end

    def translation_scope
      "controllers.instrument_unavailable_reports_controller"
    end

    private

    def formatted_total_minutes(reservation)
      duration_in_seconds =
        ReservationRowDurationCalculator
        .new(reservation, start_time: date_start.beginning_of_day, end_time: date_end.end_of_day)
        .duration_in_seconds

      format("%.2f", duration_in_seconds / 60.0)
    end

    def default_report_hash
      {
        type: ->(reservation) { reservation.class.model_name.human },
        instrument: :product,
        start_time: :reserve_start_at,
        end_time: :reserve_end_at,
        total_minutes: ->(reservation) { formatted_total_minutes(reservation) },
        admin_note: :admin_note,
        category: ->(reservation) { reservation_category_label(reservation) },
        created_by: :created_by,
      }
    end

    def report_data_query
      querier.reservations
    end

    def querier
      @querier ||=
        AdminReservationQuerier.new(facility: @facility,
                                    start_time: date_start.beginning_of_day,
                                    end_time: date_end.end_of_day)
    end

  end

end
