# frozen_string_literal: true

require "rails_helper"

RSpec.describe CancellationFeeCalculator do
  let(:order_detail) { reservation.order_detail }
  let(:calculator) { described_class.new(order_detail) }

  describe "#total_cost" do
    subject { calculator.total_cost }

    context "when there is no reservation" do
      let(:order_detail) { build(:order_detail) }
      it { is_expected.to eq(0) }
    end

    let(:instrument) { FactoryBot.create(:setup_instrument, min_cancel_hours: 24) }

    describe "when outside the cancellation window" do
      let(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument, reserve_start_at: 48.hours.from_now, reserve_end_at: 49.hours.from_now) }

      context "when there is a cancellation_cost" do
        before { instrument.price_policies.update_all(cancellation_cost: 45.75) }
        it { is_expected.to eq(0) }
      end

      it "does not change the canceled_at" do
        expect { subject }.not_to change(order_detail, :canceled_at)
      end

      it "does not change the costs" do
        expect { subject }.not_to change(order_detail, :actual_cost)
      end
    end

    describe "when inside the reservation window" do
      let!(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument, reserve_start_at: 2.hours.from_now, reserve_end_at: 3.hours.from_now) }

      context "when there is no cancellation_cost" do
        it { is_expected.to eq(0) }
      end

      context "when there is a cancellation_cost" do
        before { instrument.price_policies.update_all(cancellation_cost: 45.75) }
        it { is_expected.to eq(45.75) }

        it "is not the full price charge" do
          expect(calculator).not_to be_charge_full_price
        end
      end

      context "when the price policy is set to charge for full reservation" do
        before { instrument.price_policies.update_all(usage_rate: 1, full_price_cancellation: true) }

        describe "with the feature on", feature_setting: { "billing.charge_full_price_on_cancellation" => true } do
          it { is_expected.to eq(60) } # usage_rate is per minute
          it "is the full price charge"  do
            expect(calculator).to be_charge_full_price
          end
        end

        describe "with the feature off", feature_setting: { "billing.charge_full_price_on_cancellation" => false } do
          it { is_expected.to eq(0) }
          it "is the full price charge" do
            expect(calculator).not_to be_charge_full_price
          end
        end
      end
    end
  end
end
