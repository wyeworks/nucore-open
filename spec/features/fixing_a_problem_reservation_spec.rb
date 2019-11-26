require "rails_helper"

RSpec.describe "Fixing a problem reservation" do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :timer, :always_available, facility: facility, problems_resolvable_by_user: true) }

  before { login_as reservation.user }

  describe "a problem reservation" do
    let(:reservation) { create(:purchased_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago, actual_start_at: 1.hour.ago, actual_end_at: nil) }
    before { MoveToProblemQueue.move!(reservation.order_detail, force: true) }

    it "can edit the reservation" do
      visit reservations_path(status: :all)
      click_link "Fix Usage"
      fill_in "Actual Duration", with: "45"
      click_button "Save"
      expect(page).not_to have_content("Fix Usage")
    end

    it "updates the order detail's fields" do
      visit edit_problem_reservation_path(reservation)
      fill_in "Actual Duration", with: "45"
      click_button "Save"

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

    describe "the product is not resolvable" do
      before { instrument.update(problems_resolvable_by_user: false) }

      it "cannot edit the reservation" do
        visit edit_problem_reservation_path(reservation)
        expect(page).to have_content("You cannot edit this order")
      end
    end
  end

  describe "is both missing actuals and missing price policy" do
    let(:reservation) { create(:purchased_reservation, product: instrument) }
    before do
      reservation.update(actual_start_at: reservation.reserve_start_at)
      MoveToProblemQueue.move!(reservation.order_detail, force: true)
    end

    it "can view the page" do
      expect(reservation.order_detail).to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_field("Actual Duration")
    end
  end

  describe "not a problem" do
    let(:reservation) { create(:completed_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago) }

    it "cannot view the page" do
      expect(reservation.order_detail).not_to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_content("You cannot edit this order")
    end
  end

  describe "a problem because of missing price policy" do
    let(:reservation) { create(:completed_reservation, product: instrument) }

    it "cannot view the page" do
      expect(reservation.order_detail).to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_content("You cannot edit this order")
    end
  end
end
