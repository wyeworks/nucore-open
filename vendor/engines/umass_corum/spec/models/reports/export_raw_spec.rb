# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ExportRaw do
  let(:credit_card_account) { FactoryBot.create(:credit_card_account, :with_account_owner) }
  let(:account) { FactoryBot.build(:voucher_split_account, owner: user, primary_subaccount: credit_card_account) }

  let(:subaccounts) { account.splits.map(&:subaccount) }
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility) }

  subject(:report) { described_class.new(**report_args) }
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

  describe "with an item" do
    before { item.price_policies.update_all(unit_cost: 11, unit_subsidy: 1) }

    let(:item) { FactoryBot.create(:setup_item, facility: facility) }
    let(:order) { create(:complete_order, product: item, account: account, user: user, created_by: user.id) }
    let(:order_detail) do
      order.order_details.first.tap do |order_detail|
        order_detail.update!(
          quantity: 1,
          actual_cost: BigDecimal("19.99"),
          actual_subsidy: BigDecimal("9.99"),
          estimated_cost: BigDecimal("39.99"),
          estimated_subsidy: BigDecimal("29.99"),
        )
      end
    end

    it "splits the values in the report" do
      expect(report).to have_column_values(
        "Quantity" => ["0.5", "0.5"],
        "Actual Cost" => ["$9.99", "$10.00"],
        "Actual Subsidy" => ["$4.99", "$5.00"],
        "Estimated Cost" => ["$19.99", "$20.00"],
        "Estimated Subsidy" => ["$14.99", "$15.00"],
        "Calculated Cost" => ["$5.50", "$5.50"],
        "Calculated Subsidy" => ["$0.50", "$0.50"],
        "Account" => [credit_card_account.account_number, "MIVP"],
        "Facility" => [facility.to_s, facility.to_s],
        "Account Owner" => [credit_card_account.owner_user.username, "MIVP"],
        "Split Percent" => ["50%", "50%"],
      )
    end
  end

  describe "with a reservation", :time_travel do
    let(:instrument) { FactoryBot.create(:setup_instrument, :always_available, facility: facility) }
    let(:now) { Time.zone.parse("2016-02-01 10:30") }
    let(:reservation) do
      FactoryBot.create(:completed_reservation,
                        user: user,
                        product: instrument,
                        reserve_start_at: Time.zone.parse("2016-02-01 08:30"),
                        reserve_end_at: Time.zone.parse("2016-02-01 09:30"),
                        actual_start_at: Time.zone.parse("2016-02-01 08:30"),
                        actual_end_at: Time.zone.parse("2016-02-01 09:35"))
    end
    let(:order_detail) { reservation.order_detail }

    before { order_detail.update!(account: account) }

    it "splits the fields correctly" do
      expect(report).to have_column_values(
        "Reservation Start Time" => Array.new(2).fill(reservation.reserve_start_at.to_s),
        "Reservation End Time" => Array.new(2).fill(reservation.reserve_end_at.to_s),
        "Reservation Minutes" => ["30.0", "30.0"],
        "Actual Start Time" => Array.new(2).fill(reservation.actual_start_at.to_s),
        "Actual End Time" => Array.new(2).fill(reservation.actual_end_at.to_s),
        "Actual Minutes" => ["32.5", "32.5"],
        "Account" => [credit_card_account.account_number, "MIVP"],
        "Facility" => [facility.to_s, facility.to_s],
        "Account Owner" => [credit_card_account.owner_user.username, "MIVP"],
        "Quantity" => ["0.5", "0.5"],
      )
    end
  end

  describe "with a journaled order" do
    before { item.price_policies.update_all(unit_cost: 11, unit_subsidy: 1) }

    let(:item) { FactoryBot.create(:setup_item, facility: facility) }
    let(:order) { create(:complete_order, product: item, account: account, user: user, created_by: user.id) }
    let(:order_detail) { order.order_details.first }
    let(:journal) { create(:journal, facility: facility, updated_by: 1) }

    before :each do
      order.order_details.each do |order_detail|
        order_detail.journal = journal
        create(:journal_row, journal: journal, order_detail: order_detail, ref_2: "ALS001")
        order_detail.save!
      end
    end

    it "shows journal reference in report" do
      expect(report).to have_column_values(
        "Als Number" => ["ALS001", "ALS001"],
      )
    end
  end
end
