# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "report_spec_helper"

RSpec.describe Reports::InstrumentReportsController do
  include ReportSpecHelper

  run_report_tests([
                     { report_by: :instrument, index: 0, report_on_label: nil, report_on: proc { |res| [res.product.url_name] } },
                     { report_by: :account, index: 1, report_on_label: "Account", report_on: proc { |res| [res.product.url_name, res.order_detail.account.to_s] } },
                     { report_by: :account_owner, index: 2, report_on_label: "Account Owner", report_on: proc { |res| owner = res.order_detail.account.owner_user; [res.product.url_name, "#{owner.full_name} (#{owner.username})"] } },
                     { report_by: :purchaser, index: 3, report_on_label: "Purchaser", report_on: proc { |res| usr = res.order_detail.order.user; [res.product.url_name, "#{usr.full_name} (#{usr.username})"] } },
                   ])

  private

  def setup_extra_test_data(_user)
    start_at = parse_usa_date(@params[:date_start], "10:00 AM") + 10.days
    place_reservation(@authable, @order_detail, start_at)
    @reservation.actual_start_at = start_at
    @reservation.actual_end_at = start_at + 1.hour
    @order_detail.update_attribute(:fulfilled_at, start_at + 1.hour)
    assert @reservation.save(validate: false)
  end

  def report_headers(label)
    headers = ["Instrument", "Quantity", "Reserved Time (h)", "Percent of Reserved", "Actual Time (h)", "Percent of Actual Time"]
    headers.insert(1, label) if label
    headers += report_attributes(@reservation, @instrument) if export_all_request?
    headers
  end

  def assert_report_init(_label)
    expect(assigns(:totals).size).to eq(5)
    reservations = Reservation.all
    expect(assigns(:totals)[0].to_s).to eq(reservations.size.to_s)

    reserved_mins = reservations.map(&:duration_mins).inject(0, &:+)
    expect(assigns(:totals)[1]).to eq(to_hours(reserved_mins, 1))

    actual_mins = reservations.map(&:actual_duration_mins).inject(0, &:+)
    expect(assigns(:totals)[3]).to eq(to_hours(actual_mins, 1))

    expect(assigns(:rows)).to be_is_a Array

    # further testing in spec/models/reports/instrument_utilization_report_spec.rb
  end

end
