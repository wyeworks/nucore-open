# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing an order detail" do

  let(:facility) { create(:setup_facility) }
  let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility, control_mechanism: "timer") }
  let(:reservation) { create(:purchased_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail }
  let(:order) { reservation.order }

  let(:director) { create(:user, :facility_director, facility: facility) }

  before do
    login_as director
  end

  describe "editing an order detail with a reservation" do
    before do
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    it "can change the note" do
      fill_in "Note", with: "hello"
      click_button "Save"
      expect(order_detail.reload.note).to eq "hello"
      expect(page).to have_content("successfully updated")
    end

    it "can change reservation duration" do
      fill_in "Duration", with: "90"
      click_button "Save"
      new_end_at = order_detail.reservation.reload.reserve_start_at + 90.minutes

      expect(order_detail.reservation.reload.reserve_end_at).to eq(new_end_at)
      expect(page).to have_content("successfully updated")
    end
  end

  describe "canceling order details" do
    before do
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end
    context "canceling an item" do
      let(:item) { create(:setup_item, facility: facility) }
      let(:order) { create(:purchased_order, product: item) }
      let(:order_detail) { order.order_details.first }

      it "cancels the item" do
        select "Canceled", from: "Status"
        click_button "Save"

        expect(page).to have_content("Canceled")
        expect(page).to have_css("tfoot .currency", text: "$0.00", count: 3)
      end
    end

    context "canceling a reservation" do
      before do
        instrument.price_policies.update_all(cancellation_cost: 5)
        # reservation is set for tomorrow, we need min_cancel_hours to be longer than time to reserve_start_at
        instrument.update_attribute(:min_cancel_hours, 48)
      end

      it "cancels without a fee" do
        select "Canceled", from: "Status"
        click_button "Save"

        expect(page).to have_content("Canceled")
        expect(page).to have_css("tfoot .currency", text: "$0.00", count: 3)
      end

      it "cancels with a fee" do
        select "Canceled", from: "Status"
        check I18n.t("facility_order_details.edit.label.with_cancel_fee")
        click_button "Save"

        expect(page).to have_content("Complete")
        expect(page).to have_css("tfoot .currency", text: "$5.00", count: 2)
      end
    end
  end

  describe "reconciling an order" do
    let(:item) { create(:setup_item, facility: facility) }
    let(:order) { create(:complete_order, product: item) }
    let(:order_detail) { order.order_details.first }

    before do
      order_detail.update!(reviewed_at: 1.day.ago)
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    it "can reconcile the order", :js do
      select "Reconciled", from: "Status"
      fill_in "Reconciliation Note", with: "adding a note"
      click_button "Save"

      expect(order_detail.reload).to be_reconciled
      expect(order_detail.reconciled_note).to eq("adding a note")
    end
  end

  describe "a reconciled orderd" do
    before do
      order_detail.update!(state: :reconciled, order_status: OrderStatus.reconciled, reconciled_at: 1.day.ago, reconciled_note: "I was reconciled")
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    it "cannot do anything", :js do
      save_and_open_screenshot
      expect(page).to have_field("Reconciliation Note", with: "I was reconciled", disabled: true)
      expect(page).not_to have_button("Save")
    end
  end
end
