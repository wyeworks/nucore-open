require "rails_helper"

RSpec.describe ProblemReservationsController do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :timer, :always_available, facility: facility, problems_resolvable_by_user: true) }
  let(:problem_reservation) { create(:purchased_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago, actual_start_at: 1.hour.ago, actual_end_at: nil) }
  before { MoveToProblemQueue.move!(problem_reservation.order_detail, force: true, cause: :reservation_started) }

  # Happy path is tested in features/fixing_a_problem_reservation_spec
  describe "as the user" do
    before { sign_in problem_reservation.user }

    it "is a success" do
      get :edit, params: { id: problem_reservation }
      expect(response).to be_successful
    end

    describe "when the product is not resolvable" do
      before { instrument.update(problems_resolvable_by_user: false) }

      it "is a 404" do
        get :edit, params: { id: problem_reservation }
        expect(response).to be_not_found
      end
    end
  end

  describe "as a random user" do
    before { sign_in create(:user) }
    it "is a 404" do
      get :edit, params: { id: problem_reservation }
      expect(response).to be_not_found
    end
  end

  describe "as a facility director" do
    before { sign_in create(:user, :facility_director, facility: facility) }

    it "is a 404" do
      get :edit, params: { id: problem_reservation }
      expect(response).to be_not_found
    end
  end

  describe "as a global admin" do
    before { sign_in create(:user, :administrator) }

    it "is a 404" do
      get :edit, params: { id: problem_reservation }
      expect(response).to be_not_found
    end
  end
end
