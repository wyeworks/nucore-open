# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChargeMode do
  describe ".for_order_detail" do
    subject(:charge_for) { described_class.for_order_detail(order_detail) }

    describe "it has an assigned price policy" do
      let(:order_detail) { build(:order_detail, price_policy: price_policy) }

      describe "for an item" do
        let(:price_policy) { build(:item_price_policy) }
        it { is_expected.to eq("quantity") }
      end

      describe "for an instrument" do
        let(:price_policy) { build(:instrument_price_policy, charge_for: "overage") }
        it { is_expected.to eq("overage") }
      end
    end

    describe "with no assigned price policy and no current policy for the product" do
      let(:item) { build_stubbed(:item) }
      let(:order_detail) { build(:order_detail, price_policy: nil, product: item) }

      it { is_expected.to be_blank }
    end

    describe "with no assigned price policy but there is a current policy" do
      let(:instrument) { create(:setup_instrument) }
      let(:order_detail) { build_stubbed(:order_detail, product: instrument) }

      it { is_expected.to eq("reservation") }

      describe "and the policy is overage" do
        before { instrument.price_policies.update_all(charge_for: "overage") }

        it { is_expected.to eq("overage") }
      end
    end
  end
end
