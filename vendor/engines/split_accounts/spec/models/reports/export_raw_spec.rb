# frozen_string_literal: true

require "rails_helper"
require_relative "../../split_accounts_spec_helper"

RSpec.describe Reports::ExportRaw, :enable_split_accounts do
  let(:account) do
    FactoryBot.build(:split_account, :with_account_owner, without_splits: true, owner: user).tap do |account|
      account.splits << build(:split, percent: 50, apply_remainder: true, subaccount: subaccounts[0], parent_split_account: account)
      account.splits << build(:split, percent: 50, apply_remainder: false, subaccount: subaccounts[1], parent_split_account: account)
      account.save!
    end
  end

  let(:subaccounts) { FactoryBot.create_list(:setup_account, 2) }
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
    let(:order) { create(:complete_order, product: item, account: account) }
    let(:order_detail) do
      order.order_details.first.tap do |order_detail|
        order_detail.update_attributes!(
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
        "Actual Cost" => ["$10.00", "$9.99"],
        "Actual Subsidy" => ["$5.00", "$4.99"],
        "Estimated Cost" => ["$20.00", "$19.99"],
        "Estimated Subsidy" => ["$15.00", "$14.99"],
        "Calculated Cost" => ["$5.50", "$5.50"],
        "Calculated Subsidy" => ["$0.50", "$0.50"],
        "Account" => subaccounts.map(&:account_number),
        "Split Percent" => ["50%", "50%"],
        "Parent Account" => [account.description_to_s, account.description_to_s],
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

    before { order_detail.update_attributes!(account: account) }

    it "splits the fields correctly" do
      expect(report).to have_column_values(
        "Reservation Start Time" => Array.new(2).fill(reservation.reserve_start_at.to_s),
        "Reservation End Time" => Array.new(2).fill(reservation.reserve_end_at.to_s),
        "Reservation Minutes" => ["30.0", "30.0"],
        "Actual Start Time" => Array.new(2).fill(reservation.actual_start_at.to_s),
        "Actual End Time" => Array.new(2).fill(reservation.actual_end_at.to_s),
        "Actual Minutes" => ["32.5", "32.5"],
        "Quantity" => ["0.5", "0.5"],
      )
    end
  end

  # There was a bug from the Rails 5 upgrade where reservations on split accounts
  # got deleted. We want to make sure the reports don't break on them.
  describe "with a broken reservation" do
    let(:instrument) { FactoryBot.create(:setup_instrument, :always_available, facility: facility) }
    let(:reservation) do
      FactoryBot.create(:completed_reservation,
                        user: user,
                        product: instrument,
                       )
    end
    let(:order_detail) { reservation.order_detail }
    before do
      instrument.price_policies.each { |pp| pp.update(start_date: 3.days.ago, usage_rate: 60) }
      order_detail.update_attributes!(account: account)
      reservation.really_destroy!
    end

    it "displays the information" do
      expect(report).to have_column_values(
        "Reservation Start Time" => ["", ""],
        "Actual Cost" => ["$30.00", "$30.00"],
        "Calculated Cost" => ["$0.00", "$0.00"],
        "Quantity" => ["0.5", "0.5"],
      )
    end
  end
end
