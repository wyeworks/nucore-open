# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing mode workflows" do
  let(:facility) { create(:setup_facility, accepts_po:) }
  let(:accepts_po) { true }
  let(:billing_mode) { "Default" }
  let(:item) { create(:setup_item, facility:, billing_mode:) }
  let(:order) { create(:setup_order, product: item, account: create(:purchase_order_account, :with_account_owner, facility:)) }
  let(:order_detail) { order.order_details.first }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:user) { order.account.owner.user }
  let(:logged_in_user) { nil }

  before do
    login_as logged_in_user
  end

  describe "'Skip Review' billing mdoe" do
    let(:billing_mode) { "Skip Review" }

    context "with a valid account" do
      let(:logged_in_user) { director }

      it "automatically moves an order detail from complete to reconciled", :js do
        order._validate_order!
        order.purchase!
        visit manage_facility_order_order_detail_path(facility, order, order_detail)

        select "Complete", from: "Order Status"

        click_button "Save"
        visit facility_transactions_path(facility)

        expect(page).to have_selector("tr td.nowrap", text: "Reconciled")
      end
    end

    context "when a user forgets to end their reservation on an instrument that charges for actuals" do
      let(:logged_in_user) { user }

      let(:instrument) do
        create(
          :setup_instrument,
          :timer,
          :always_available,
          charge_for: :usage,
          facility:, problems_resolvable_by_user: true,
          billing_mode:
        )
      end

      let!(:old_reservation) do
        create(
          :purchased_reservation,
          product: instrument,
          reserve_start_at: 2.hours.ago,
          reserve_end_at: 1.hour.ago,
          actual_start_at: 1.hour.ago,
          actual_end_at: nil
        )
      end

      before do
        visit facility_instrument_path(facility, instrument)
      end

      it "starts a new reservation and moves the old one to the problem queue" do
        click_on "Create"
        expect(page).to have_content "The instrument has been activated successfully"
        # Check the problem reservation is in the problem queue
        login_as director
        visit show_problems_facility_reservations_path(facility)
        expect(page).to have_content old_reservation.order_detail.id
        expect(page).to have_content "Missing Actuals"
      end
    end

    context "with an invalid account" do
      let(:accepts_po) { false }
      let(:logged_in_user) { user }

      it "does not allow the product to be ordered" do
        visit facility_item_path(facility, item)
        expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this item")
      end
    end
  end

  describe "'Nonbillable' billing mode" do
    let(:billing_mode) { "Nonbillable" }
    let(:logged_in_user) { director }

    it "automatically moves an order detail from complete to reconciled", :js do
      order._validate_order!
      order.purchase!
      visit manage_facility_order_order_detail_path(facility, order, order_detail)

      select "Complete", from: "Order Status"

      click_button "Save"
      visit facility_transactions_path(facility)

      expect(page).to have_selector("tr td.nowrap", text: "Reconciled")
    end
  end
end
