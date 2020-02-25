# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editing an occupancy" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let!(:policy) { create(:secure_room_price_policy, product: secure_room, usage_rate: 60, price_group: order_detail.account.price_groups.first) }
  let(:order) { create(:purchased_order, product: secure_room) }
  let!(:order_detail) { order.order_details.first }

  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:occupancy) do
    create(
      :occupancy,
      *traits,
      secure_room: secure_room,
      order_detail: order_detail,
      account: order_detail.account,
      entry_at: entry_at,
      exit_at: exit_at,
    )
  end

  before do
    order_detail.complete!
    login_as director
    visit facility_transactions_path(facility)
    first("a.manage-order-detail", text: order_detail.id).click
  end

  describe "with a complete occupancy", :aggregate_failures do
    let(:traits) { :complete }
    let(:entry_at) { Time.zone.parse("2017-09-12 08:30") }
    let(:exit_at) { Time.zone.parse("2017-09-12 09:30") }

    it "can change the times" do
      fill_in "order_detail_occupancy_attributes_entry_at_date", with: "04/12/2017"
      select "7", from: "order_detail_occupancy_attributes_entry_at_hour"
      select "10", from: "order_detail_occupancy_attributes_entry_at_minute"
      select "PM", from: "order_detail_occupancy_attributes_entry_at_ampm"

      fill_in "order_detail_occupancy_attributes_exit_at_date", with: "4/12/2017"
      select "8", from: "order_detail_occupancy_attributes_exit_at_hour"
      select "00", from: "order_detail_occupancy_attributes_exit_at_minute"
      select "PM", from: "order_detail_occupancy_attributes_exit_at_ampm"

      fill_in "Price", with: "45.37"

      fill_in "Pricing Note", with: "i am a note"

      click_button "Save"

      expect(occupancy.reload.entry_at).to eq(Time.zone.parse("2017-04-12 19:10"))
      expect(occupancy.exit_at).to eq(Time.zone.parse("2017-04-12 20:00"))

      expect(order_detail.reload.actual_cost).to eq(45.37)
    end
  end

  describe "with an orphaned swipe in" do
    let(:traits) { :orphan }
    let(:entry_at) { Time.zone.parse("2017-09-12 08:30") }
    let(:exit_at) { nil }

    it "can set the end time" do
      fill_in "order_detail_occupancy_attributes_exit_at_date", with: "9/12/2017"
      select "9", from: "order_detail_occupancy_attributes_exit_at_hour"
      select "45", from: "order_detail_occupancy_attributes_exit_at_minute"
      select "AM", from: "order_detail_occupancy_attributes_exit_at_ampm"

      click_button "Save"

      expect(occupancy.reload.entry_at).to eq(Time.zone.parse("2017-09-12 08:30"))
      expect(occupancy.exit_at).to eq(Time.zone.parse("2017-09-12 09:45"))
      expect(order_detail.reload.fulfilled_at).to eq(occupancy.exit_at)
    end

    it "errors if no end time is set" do
      click_button "Save"

      expect(page).to have_content("Error while updating order")
    end
  end

  describe "with an orphaned swipe out" do
    let(:traits) { :orphan }
    let(:entry_at) { nil }
    let(:exit_at) { Time.zone.parse("2017-09-12 10:30") }

    it "can set the start time" do
      fill_in "order_detail_occupancy_attributes_entry_at_date", with: "9/12/2017"
      select "9", from: "order_detail_occupancy_attributes_entry_at_hour"
      select "45", from: "order_detail_occupancy_attributes_entry_at_minute"
      select "AM", from: "order_detail_occupancy_attributes_entry_at_ampm"

      click_button "Save"

      expect(occupancy.reload.entry_at).to eq(Time.zone.parse("2017-09-12 09:45"))
      expect(occupancy.exit_at).to eq(Time.zone.parse("2017-09-12 10:30"))
      expect(order_detail.reload.fulfilled_at).to eq(occupancy.exit_at)
    end
  end
end
