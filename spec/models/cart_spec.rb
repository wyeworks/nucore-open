# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cart do
  describe "instrument_only_carts" do
    let(:carts) { Cart.abandoned_carts }
    let(:instrument) { FactoryBot.create(:setup_instrument) }
    let(:item) { FactoryBot.create(:setup_item, facility: instrument.facility) }
    before :each do
      @purchased_instrument_order = FactoryBot.create(:purchased_reservation, product: instrument, reserve_start_at: 2.hours.from_now, reserve_end_at: 3.hours.from_now).order
      @instrument_order = FactoryBot.create(:setup_reservation, product: instrument).order

      @instrument_and_item_order = FactoryBot.create(:setup_reservation, product: instrument).order
      @instrument_and_item_order.add(item, 1)

      @two_instrument_order = FactoryBot.create(:setup_reservation, product: instrument).order
      @two_instrument_order.add(@two_instrument_order.order_details.first.product, 1)

      @item_order = FactoryBot.create(:setup_order, product: item)
    end

    # setup is expensive, so only do it once and test several things at once
    it "should include the proper orders" do
      expect(carts).not_to include @purchased_instrument_order
      expect(carts).to include @instrument_order
      expect(carts).not_to include @instrument_and_item_order
      expect(carts).not_to include @two_instrument_order
      expect(carts).not_to include @item_order
    end

    context "destroy_all_instrument_only_carts" do
      let(:all_orders) { Order.all }
      before :each do
        Cart.destroy_all_instrument_only_carts(2.minutes.from_now)
      end

      it "should have removed only the orders it should have" do
        expect(all_orders).to include @purchased_instrument_order
        expect(all_orders).not_to include @instrument_order
        expect(all_orders).to include @instrument_and_item_order
        expect(all_orders).to include @two_instrument_order
        expect(all_orders).to include @item_order
      end
    end

    context "destroy_all_instrument_only_carts with time" do
      it "should not remove if the order has been updated since the time" do
        Cart.destroy_all_instrument_only_carts(1.day.ago)
        expect(Order.all).to include @instrument_order
      end

      it "should destroy if the order has not been updated since the time" do
        Cart.destroy_all_instrument_only_carts(1.minute.from_now)
        expect(Order.all).not_to include @instrument_order
      end
    end
  end
end
