# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProblemReservationResolver do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility: facility, problems_resolvable_by_user: true) }
  let(:user) { create(:user) }
  let!(:problem_reservation) do
    create(
      :purchased_reservation,
      product: instrument,
      reserve_start_at: 2.hours.ago,
      reserve_end_at: 1.hour.ago,
      actual_start_at: 1.hour.ago,
      actual_end_at: nil
    )
  end
  subject(:resolver) { described_class.new(problem_reservation) }

  before { MoveToProblemQueue.move!(problem_reservation.order_detail) }

  describe "resolve" do
    it "sets the problem resolution attributes" do
      resolver.resolve(actual_end_at: 15.minutes.ago, current_user: user)

      expect(problem_reservation.order_detail.reload).to have_attributes(
        problem_description_key_was: "missing_actuals",
        problem_resolved_at: be_present,
        problem_resolved_by: user,
      )
    end

    it "moves the fulfilled_at to the actual_end_at" do
      end_at = 15.minutes.ago
      expect do
        resolver.resolve(actual_end_at: end_at)
      end.to change { problem_reservation.order_detail.reload.fulfilled_at }.to eq(end_at)
    end

    describe "when there is no price policy" do
      before { instrument.price_policies.destroy_all }

      it "leaves it as a problem reservation" do
        resolver.resolve(actual_end_at: 15.minutes.ago)
        expect(problem_reservation.order_detail.reload.problem_description_key_was).to eq("missing_actuals")
        expect(problem_reservation.order_detail.problem_description_key).to eq(:missing_price_policy)
      end
    end

    it "adds an error to the reservation if it is invalid" do
      # Reservations cannot be zero length
      expect(resolver.resolve(actual_end_at: problem_reservation.actual_start_at)).to be_falsy
      expect(problem_reservation.errors).to be_added(:actual_duration_mins, :zero_minutes)
    end

  end

end
