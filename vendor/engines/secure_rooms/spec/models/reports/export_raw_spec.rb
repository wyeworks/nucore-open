# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ExportRaw, :time_travel do
  let(:now) { Time.zone.parse("2016-02-01 10:30") }
  let(:user) { create(:user) }
  let(:facility) { secure_room.facility }

  let(:occupancy) do
    create(
      :occupancy,
      :with_order_detail,
      user: user,
      account:,
      entry_at: Time.zone.parse("2016-02-01 08:30"),
      exit_at: Time.zone.parse("2016-02-01 09:35"),
    )
  end
  let(:order_detail) { occupancy.order_detail }
  let(:secure_room) { occupancy.secure_room }

  let(:report) { described_class.new(**report_args) }
  let(:report_args) do
    {
      action_name: "general",
      facility_url_name: facility.url_name,
      order_status_ids: [order_detail.order_status_id],
      date_end: 1.day.from_now,
      date_start: 1.day.ago,
      date_range_field: "ordered_at",
    }
  end

  let(:headers) { report.column_headers }
  let(:lines) { report.to_csv.split("\n") }
  let(:cells) { lines.map { |line| line.split(",") } }
  let(:cells_without_headers) { cells[1..-1] }
  let(:column_values) { cells_without_headers.pluck(column_index) }
  let(:column_index) { headers.index(column_header) }

  before do
    create(:account_price_group_member, account:, price_group: PriceGroup.base)
  end

  describe "normal accounts" do
    let(:account) { create(:setup_account, owner: user) }

    it "populates the report properly" do
      expect(report).to have_column_values(
        "Fulfilled At" => occupancy.exit_at.to_s,
        "Quantity" => "1",
        "Product" => secure_room.name,
        "Product Type" => "Secure Room",
        "Estimated Cost" => "",
        "Estimated Subsidy" => "",
        "Estimated Total" => "",
        "Reservation Start Time" => "",
        "Reservation End Time" => "",
        "Reservation Minutes" => "",
        "Actual Cost" => "$65.00",
        "Actual Subsidy" => "$10.83",
        "Actual Total" => "$54.17",
        "Actual Start Time" => occupancy.entry_at.to_s,
        "Actual End Time" => occupancy.exit_at.to_s,
        "Actual Minutes" => "65",
      )
    end
  end

  describe "split accounts", :enable_split_accounts do
    let(:account) { create(:split_account, owner: user) }

    it "splits and populates the report properly" do
      expect(report).to have_column_values(
        "Actual Start Time" => Array.new(2).fill(occupancy.entry_at.to_s),
        "Actual End Time" => Array.new(2).fill(occupancy.exit_at.to_s),
        "Actual Minutes" => ["32.5", "32.5"],
        "Quantity" => ["0.5", "0.5"],
      )
    end
  end
end
