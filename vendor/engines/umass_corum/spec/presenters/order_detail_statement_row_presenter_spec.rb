require "rails_helper"

RSpec.describe UmassCorum::OrderDetailStatementRowPresenter do
  include ActionView::Helpers::NumberHelper

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

  context "when the product is daily booking" do
    let(:instrument) { create :setup_instrument, :daily_booking, :always_available, facility: }
    let(:reservation_order) { create(:setup_order, product: instrument, account:) }
    let(:account) { create(:setup_account, facility:) }
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        order_detail: reservation_order.order_details.first,
        reserve_start_at: 4.days.ago,
        reserve_end_at: 1.day.ago,
        actual_start_at: 4.days.ago,
        actual_end_at: 1.day.ago
      )
    end

    before do
      order_detail = reservation_order.order_details.first
      order_detail.complete!
    end

    it "returns the correct duration" do
      expect(presenter.quantity).to eq "3"
    end

    it "returns the correct unit of measure" do
      expect(presenter.unit_of_measure).to eq "day"
    end

    it "returns the correct rate" do
      expect(presenter.hourly_rate).to eq(number_to_currency(price_policy.usage_rate_daily))
    end
  end
end
