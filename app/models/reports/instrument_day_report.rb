# frozen_string_literal: true

class Reports::InstrumentDayReport
  def initialize(reservations)
    @reservations = reservations
  end

  def build_report
    @data = {}
    @totals = DataRow.new
    @reservations.each do |reservation|
      data_value = yield reservation
      @data[reservation.product.name] ||= DataRow.new
      @data[reservation.product.name].add(data_value)
      @totals.add(data_value)
    end
  end

  def rows
    @data.sort.map do |key, data_row|
      [key] + data_row
    end
  end

  def totals
    @totals.to_ary
  end

  class DataRow
    def initialize(*_args)
      @data = [0, 0, 0, 0, 0, 0, 0]
    end

    def add(new_data)
      @report_type = new_data

      @data[new_data.day] += new_data.value
    end

    def to_ary
      @data.map { |value| @report_type.try(:transform, value) }
    end
  end

  class DayValue
    include ActionView::Helpers::NumberHelper

    def initialize(reservation)
      @reservation = reservation
    end

    def day
      raise NotImplementedError.new("Subclass must implement")
    end

    def value
      raise NotImplementedError.new("Subclass must implement")
    end

    def transform(data)
      data
    end
  end

  class ReservedQuantity < DayValue
    def day
      @reservation.reserve_start_at.wday
    end

    def value
      @reservation.quantity
    end

    def transform(data)
      number_with_precision(data, strip_insignificant_zeros: true)
    end
  end

  class ReservedHours < DayValue
    include ReportsHelper

    def day
      @reservation.reserve_start_at.wday
    end

    def value
      @reservation.duration_mins
    end

    def transform(data)
      to_hours(data, 1)
    end
  end

  class ActualHours < DayValue
    include ReportsHelper

    def day
      @reservation.reserve_start_at.try(:wday) || 0
    end

    def value
      @reservation.actual_duration_mins.to_i
    end

    def transform(data)
      to_hours(data, 1)
    end
  end

  class ActualQuantity < DayValue
    def day
      @reservation.actual_start_at.try(:wday) || 0
    end

    def value
      @reservation.actual_start_at.present? ? @reservation.quantity : 0
    end

    def transform(data)
      number_with_precision(data, strip_insignificant_zeros: true)
    end
  end
end
