# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentPricePolicy do
  before :each do
    @instrument = FactoryBot.create(:setup_instrument)
    expect(@instrument.price_policies.count).to eq(1)
    @price_policy = @instrument.price_policies.first
    @price_policy.update(usage_rate: 0,
                                    usage_subsidy: 0,
                                    minimum_cost: 0,
                                    cancellation_cost: 0)

    @reservation = FactoryBot.create(:purchased_reservation, product: @instrument,
                                                             reserve_start_at: 1.day.ago, reserve_end_at: 1.day.ago + 1.hour)
    @order_detail = @reservation.reload.order_detail
    @order_detail.assign_estimated_price
  end

  it "should have estimated costs at zero" do
    expect(@order_detail.estimated_cost).to eq(0)
    expect(@order_detail.estimated_subsidy).to eq(0)
  end

  it "should not have actual prices set" do
    expect(@order_detail.actual_cost).to be_nil
    expect(@order_detail.actual_subsidy).to be_nil
  end

  it "should not have a price policy set" do
    expect(@order_detail.price_policy).to be_nil
  end

  context "completed" do
    before :each do
      @order_detail.change_status! OrderStatus.find_by(name: "Complete")
      expect(@order_detail.state).to eq("complete")
    end

    it "should have actual prices set" do
      expect(@order_detail.actual_cost).to eq(0)
      expect(@order_detail.actual_subsidy).to eq(0)
    end

    it "should have a price policy set" do
      expect(@order_detail.price_policy).to eq(@price_policy)
    end
  end

end
