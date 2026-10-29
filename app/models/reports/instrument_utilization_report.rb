# frozen_string_literal: true

class Reports::InstrumentUtilizationReport
  attr_accessor :key_length
  def initialize(reservations)
    @reservations = reservations
  end

  def build_report
    @data = {}
    @totals = DataRow.new(0, 0, 0)

    @reservations.each do |reservation|
      grouping = if block_given?
                   yield(reservation).to_s
                 else
                   grouping = nil
                 end
      key = [reservation.product.name, grouping].compact
      @key_length = [@key_length.to_i, key.length].max
      add_reservation(key, reservation)
    end
  end

  def rows
    sorted_data.map do |key, data_row|
      key + data_row.row_with_percents(@totals)
    end
  end

  def totals
    @totals.row_with_percents(@totals)
  end

  def add_reservation(key, reservation)
    @data[key] ||= DataRow.new(0, 0, 0)
    data_row = DataRow.new(reservation.quantity, reservation.duration_mins, reservation.actual_duration_mins)
    @data[key] += data_row
    @totals += data_row
  end

  class DataRow
    include ReportsHelper
    include ActionView::Helpers::NumberHelper

    attr_accessor :quantity, :reserved_mins, :actual_mins
    def initialize(quantity, reserved_mins, actual_mins)
      @quantity = quantity
      @reserved_mins = reserved_mins
      @actual_mins = actual_mins
    end

    def +(other)
      DataRow.new(quantity + other.quantity,
                  reserved_mins + other.reserved_mins,
                  actual_mins + other.actual_mins.to_f)
    end

    def /(other)
      DataRow.new(to_percent(safe_divide(quantity, other.quantity)),
                  to_percent(safe_divide(reserved_mins, other.reserved_mins)),
                  to_percent(safe_divide(actual_mins, other.actual_mins.to_f)))
    end

    def safe_divide(a, b)
      return 0.0 if b.zero?
      a.to_f / b.to_f
    end

    def row_with_percents(totals)
      percent = self / totals
      [number_with_precision(quantity, strip_insignificant_zeros: true),
       to_hours(reserved_mins, 1),
       format_percent(percent.reserved_mins),
       to_hours(actual_mins, 1),
       format_percent(percent.actual_mins)]
    end
  end

  private

  def sorted_data
    @data.sort { |(a, _), (b, _)| a.compact <=> b.compact }
  end
end
