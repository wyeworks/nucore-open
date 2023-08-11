# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing an order detail" do

  let(:facility) { create(:setup_facility) }
  let!(:account) { create(:setup_account, :with_account_owner, facility: order_detail.facility, owner: order_detail.user) }
  let(:instrument) { create(:setup_instrument, :timer, facility: facility) }
  let(:reservation) { create(:purchased_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail }
  let(:order) { reservation.order }
  let(:administrator) { create(:user, :administrator) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:logged_in_user) { director }

  before do
    login_as logged_in_user
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

    it "can change the payment source" do
      select account.to_s, from: "Payment Source"
      click_button "Save"
      click_link order_detail.to_s

      expect(order_detail.reload.account).to eq(account)
      expect(page).to have_content(account.to_s)
    end
  end

  describe "order detail with missing form" do
    let(:service) { create(:setup_service, :with_order_form, facility: facility) }
    let!(:order) { create(:purchased_order, product: service) }
    let(:order_detail) { order.order_details.first }

    before do
      order_detail.change_status!(OrderStatus.in_process)
      order_detail.change_status!(OrderStatus.complete)
      order_detail.reviewed_at = 1.day.ago
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    it "allows admins to skip missing form" do
      expect(order_detail).to be_missing_form
      click_button "Skip missing form"
      expect(page).to have_content("Missing form successfully skipped")
      order_detail.reload
      expect(order_detail).not_to be_missing_form
    end
  end

  describe "order detail with missing survey" do
    let(:service) { create(:setup_service, facility: facility) }
    let!(:order) { create(:purchased_order, product: service) }
    let(:order_detail) { order.order_details.first }

    before do
      order_detail.change_status!(OrderStatus.in_process)
      order_detail.change_status!(OrderStatus.complete)
      order_detail.reviewed_at = 1.day.ago
      allow_any_instance_of(Service).to receive(:active_survey?).and_return(true)
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    it "allows admins to skip missing form" do
      expect(order_detail).to be_missing_form
      click_button "Skip missing form"
      expect(page).to have_content("Missing form successfully skipped")
      order_detail.reload
      expect(order_detail).not_to be_missing_form
    end
  end

  describe "editing a problem order detail with a reservation" do
    let(:instrument) { create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility: facility) }
    let!(:reservation) do
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
      MoveToProblemQueue.move!(reservation.order_detail, cause: :reservation_started)
    end

    it "canont enter 0 minutes for actual duration" do
      # Confirm the reservation is listed as a problem
      visit show_problems_facility_reservations_path(facility)
      expect(page).to have_content(reservation.order_detail.id)

      # Enter 0 min and get an error
      click_link "Update"
      fill_in "Actual Duration", with: "0"
      click_button "Save"
      expect(page).to have_content("Actual duration must be at least 1 minute")

      # Confirm the reservation is still listed as a problem
      visit show_problems_facility_reservations_path(facility)
      expect(page).to have_content(reservation.order_detail.id)
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

        # Happy path coverage for canceled items in the order detail form
        click_link order_detail.to_s
        expect(page).to have_content("Canceled")
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

  describe "resolving a dispute", :js do
    describe "a simple order detail" do
      let(:item) { create(:setup_item, facility: facility) }
      let(:order) { create(:complete_order, product: item) }
      let(:order_detail) do
        order.order_details.first.tap do |od|
          od.update!(reviewed_at: 5.days.ago, dispute_at: 3.days.ago, dispute_reason: "asdsfa")
        end
      end

      it "can resolve the order detail" do
        visit manage_facility_order_order_detail_path(facility, order_detail.order, order_detail)
        fill_in "Resolution Notes", with: "a resolution"
        click_button "Resolve Dispute"

        expect(order_detail.reload.dispute_resolved_at).to be_present
        expect(LogEvent).to be_exist(loggable: order_detail, event_type: :resolve)
      end
    end

    describe "and it has an accessory" do
      let(:product) { FactoryBot.create(:instrument_with_accessory, facility: facility) }
      let(:reservation) { FactoryBot.create(:completed_reservation, product: product) }
      let(:order_detail) do
        reservation.order_detail.tap do |od|
          od.update!(reviewed_at: 5.days.ago, dispute_at: 3.days.ago, dispute_reason: "asdsfa")
        end
      end
      let(:accessorizer) { Accessories::Accessorizer.new(reservation.order_detail) }

      it "can resolve the order detail" do
        visit manage_facility_order_order_detail_path(facility, order_detail.order, order_detail)
        fill_in "Resolution Notes", with: "a resolution"
        click_button "Resolve Dispute"

        expect(order_detail.reload.dispute_resolved_at).to be_present
        expect(LogEvent).to be_exist(loggable: order_detail, event_type: :resolve)
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
      expect(page).to have_field("Reconciliation Note", with: "I was reconciled", disabled: true)
      expect(page).not_to have_button("Save")
    end
  end

  describe "updating fulfilled date of a completed order" do
    before do
      order_detail.update!(state: :complete, fulfilled_at: 3.days.ago, order_status: OrderStatus.complete)
      reservation.actual_start_at = 2.hours.ago
      reservation.actual_end_at = 1.hour.ago
      reservation.save
      order_detail.price_policy = create(:item_price_policy, product: order_detail.product, price_group: PriceGroup.globals.first)
      order_detail.save
      visit manage_facility_order_order_detail_path(facility, order, order_detail)
    end

    context "as global admin" do
      let(:logged_in_user) { administrator }

      before do
        expect(page).to have_selector("input[name='order_detail[fulfilled_at]']")
        fill_in "order_detail[fulfilled_at]", with: SpecDateHelper.format_usa_date(1.day.ago)
        click_button "Save"
        expect(page).to have_content("The order was successfully updated.")
        click_link order_detail.to_s
      end

      it "can update the fulfilled at date", :js do
        expect(page).to have_content(SpecDateHelper.format_usa_date(1.day.ago))
        expect(page).not_to have_content("invalid date format")
        expect(page).to have_field("order_detail[fulfilled_at]", with: SpecDateHelper.format_usa_date(1.day.ago))
      end

      it "logs fulfilled at date updates" do
        expect(LogEvent).to be_exists(loggable: order_detail, event_type: :updated_fulfilled_at, user: logged_in_user)
      end
    end

    context "as non-global admin" do
      let(:logged_in_user) { director }

      it "cannont update the fulfilled at date" do
        expect(page).to have_no_selector("input[name='order_detail[fulfilled_at]']")
      end
    end
  end
end
