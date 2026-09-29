# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::ProblemResolutionPolicy do
  let(:facility) { create(:setup_facility) }

  subject(:policy) { described_class.new(order_detail) }

  def problem_order_detail_for(instrument)
    reservation = create(
      :purchased_reservation,
      product: instrument,
      reserve_start_at: 2.hours.ago,
      reserve_end_at: 1.hour.ago,
      actual_start_at: 1.hour.ago,
      actual_end_at: nil,
    )
    MoveToProblemQueue.move!(reservation.order_detail, cause: :reservation_started)
    reservation.order_detail.reload
  end

  describe "#notification_group" do
    context "when the user can resolve the problem themselves" do
      let(:instrument) do
        create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility:, problems_resolvable_by_user: true)
      end
      let(:order_detail) { problem_order_detail_for(instrument) }

      it { expect(policy.notification_group).to eq(:resolvable) }
    end

    context "when the user cannot resolve the problem themselves" do
      let(:instrument) do
        create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility:, problems_resolvable_by_user: false)
      end
      let(:order_detail) { problem_order_detail_for(instrument) }

      it { expect(policy.notification_group).to eq(:non_resolvable) }
    end
  end
end
