require "rails_helper"

RSpec.describe UmassCorum::OrderDetailStatementRowPresenter do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility:) }
  let!(:price_policy) { create(:instrument_price_policy, start_date: 1.week.ago, price_group: PriceGroup.base, product: instrument) }
  let(:reserve_start_at) { 24.hours.ago }
  let(:reserve_end_at) { 23.hours.ago }
  let(:reservation) { create(:completed_reservation, product: instrument, reserve_start_at:, reserve_end_at:) }

  let(:order_detail) do
    od = reservation.order_detail
    od.assign_price_policy
    od.save!
    od
  end

  let(:presenter) { described_class.new order_detail }

  describe "#quantity" do
    context "when the ordered reservation is completed" do
      it "returns the correct duration" do
        expect(presenter.quantity).to eq "1:00"
      end
    end

    context "when the ordered reservation is completed with a canceled reason" do
      before do
        order_detail.canceled_reason = "auto canceled by system"
        order_detail.save
      end

      it "returns nil" do
        expect(presenter.quantity).to be_nil
      end
    end
  end
end
