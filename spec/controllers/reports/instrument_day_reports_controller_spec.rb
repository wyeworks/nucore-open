# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "report_spec_helper"

RSpec.describe Reports::InstrumentDayReportsController do
  include ReportSpecHelper

  tab_offset = Reports::InstrumentReportsController.reports.size
  run_report_tests([
                     { report_by: :reserved_quantity, index: 0 + tab_offset, report_on_label: nil, report_on: proc { |res| Reports::InstrumentDayReport::ReservedQuantity.new(res) } },
                     { report_by: :reserved_hours, index: 1 + tab_offset, report_on_label: nil, report_on: proc { |res| Reports::InstrumentDayReport::ReservedHours.new(res) } },
                     { report_by: :actual_quantity, index: 2 + tab_offset, report_on_label: nil, report_on: proc { |res| Reports::InstrumentDayReport::ActualQuantity.new(res) } },
                     { report_by: :actual_hours, index: 3 + tab_offset, report_on_label: nil, report_on: proc { |res| Reports::InstrumentDayReport::ActualHours.new(res) } },
                   ])

  private

  def setup_extra_test_data(_user)
    start_at = Time.zone.parse("#{@params[:date_start]} 10:00 AM") + 10.days
    place_reservation(@authable, @order_detail, start_at)
    @reservation.actual_start_at = start_at
    @reservation.actual_end_at = start_at + 1.hour
    assert @reservation.save(validate: false)
  end

  def report_headers(_label)
    headers = %w(Instrument Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    headers += report_attributes(@reservation, @instrument) if export_all_request?
    headers
  end

  def assert_report_init(_label)
    expect(assigns(:totals)).to be_is_a Array
    expect(assigns(:totals).size).to eq(7)

    ndx = @reservation.actual_start_at.wday
    assigns(:totals).each_with_index do |sum, i|
      if i == ndx
        expect(sum.to_f).to be > 0
      else
        expect(sum.to_f).to eq(0)
      end
    end

    instruments = Instrument.all
    expect(assigns(:rows)).to be_is_a Array
    expect(assigns(:rows).size).to eq(instruments.count)

    assigns(:rows).each do |row|
      expect(row.size).to eq(8)
      expect(instruments.collect(&:name)).to be_include(row[0])
      # Float(data) will raise an error if it's not a valid number
      row[1..-1].all? { |data| expect(Float(data)).to be_is_a(Numeric) }
    end
  end

end
