# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fixing a problem reservation" do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility: facility, problems_resolvable_by_user: true) }

  before { login_as reservation.user }

  # Permissions and some other failure cases are covered in controllers/problem_reservations_controller_spec
  # and services/problem_reservation_resolver_spec
  describe "a problem reservation" do
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
    before { MoveToProblemQueue.move!(reservation.order_detail, cause: :reservation_started) }

    it "can edit the reservation" do
      visit reservations_path(status: :all)
      click_link "Fix Usage"
      fill_in "Actual Duration", with: "45"
      click_button "Save"

      expect(page).not_to have_content("Fix Usage")
      expect(reservation.order_detail.reload.problem_description_key_was).to eq("missing_actuals")
      expect(reservation.order_detail.problem_resolved_at).to be_present
      expect(reservation.order_detail.problem_resolved_by).to eq(reservation.user)
    end

    it "errors if zero" do
      visit edit_problem_reservation_path(reservation)
      fill_in "Actual Duration", with: "0"
      click_button "Save"
      expect(page).to have_content("at least 1 minute")
    end

    describe "when the product has available accessories" do
      let!(:accessory) { create(:time_based_accessory, parent: instrument) }

      it "allows you to add the accessory" do
        visit edit_problem_reservation_path(reservation)
        fill_in "Actual Duration", with: "45"
        click_button "Save"

        check accessory.name
        click_button "Save Changes"
        expect(page).to have_content "1 accessory added"
      end
    end
  end

  describe "is both missing actuals and missing price policy" do
    let(:reservation) { create(:purchased_reservation, :yesterday, product: instrument) }

    before do
      instrument.price_policies.destroy_all
      reservation.update!(actual_start_at: reservation.reserve_start_at)
      MoveToProblemQueue.move!(reservation.order_detail, force: true, cause: :reservation_started)
    end

    it "can view the page" do
      expect(reservation.order_detail).to be_problem
      expect(reservation.order_detail.problem_description_keys).to include(:missing_price_policy)
      expect(reservation.order_detail.problem_description_keys).to include(:missing_actuals)
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_field("Actual Duration")
    end
  end

  describe "not a problem" do
    let(:reservation) { create(:completed_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago) }

    it "cannot view the page" do
      expect(reservation.order_detail).not_to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page.status_code).to eq(404)
    end

    describe "but it was a problem" do
      before { reservation.order_detail.update(problem_resolved_at: 1.day.ago) }

      it "has a helpful message" do
        visit edit_problem_reservation_path(reservation)
        expect(page).to have_content("This reservation has already been fixed")
      end
    end
  end

  describe "a problem because of missing price policy" do
    let(:reservation) { create(:completed_reservation, product: instrument) }

    it "cannot view the page" do
      expect(reservation.order_detail).to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page.status_code).to eq(404)
    end
  end
end
