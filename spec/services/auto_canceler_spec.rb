# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutoCanceler, :time_travel do
  # Need to travel later in the day so that previous reservations can be made in the day
  let(:now) { Time.zone.parse("#{Date.today} 12:30:00") }

  after :each do
    travel_back
  end

  let(:base_date) { Time.zone.parse("#{Date.today} 12:30:00") }
  let(:instrument) { FactoryBot.create :setup_instrument }
  let!(:future_reservation) do
    FactoryBot.create :purchased_reservation,
                      product: instrument,
                      reserve_start_at: base_date + 1.day,
                      reserve_end_at: base_date + 1.day + 1.hour
  end

  let!(:past_reservation) do
    FactoryBot.create :purchased_reservation,
                      product: instrument,
                      reserve_start_at: base_date - 2.hours,
                      reserve_end_at: base_date - 1.hour,
                      reserved_by_admin: true
  end

  let!(:completed_reservation) do
    res = FactoryBot.create :purchased_reservation,
                            product: instrument,
                            reserve_start_at: base_date - 3.hours,
                            reserve_end_at: base_date - 2.hours,
                            reserved_by_admin: true
    res.order_detail.to_complete!
    res
  end

  let(:canceled_status) { OrderStatus.canceled }

  let(:canceler) { AutoCanceler.new }

  context "with auto-cancel minutes" do
    before :each do
      instrument.update(auto_cancel_mins: 10, min_cancel_hours: 1)
    end

    it "should find the past reservation in cancelable" do
      expect(canceler.cancelable_reservations.to_a).to eq([past_reservation])
    end

    it "should not cancel the future reservation" do
      canceler.cancel_reservations
      expect(future_reservation.order_detail.reload.order_status).not_to eq(canceled_status)
    end

    it "should cancel the past reservation" do
      canceler.cancel_reservations
      expect(past_reservation.order_detail.reload.order_status).to eq(canceled_status)
    end

    it "should not cancel the completed reservation" do
      canceler.cancel_reservations
      expect(completed_reservation.order_detail.reload.order_status).not_to eq(canceled_status)
    end

    it "should not cancel a past reservation in the cart" do
      cart_reservation = FactoryBot.create(:setup_reservation,
                                           product: instrument,
                                           reserve_start_at: base_date - 1.day,
                                           reserve_end_at: base_date - 1.day + 1.hour,
                                           reserved_by_admin: true)

      canceler.cancel_reservations
      expect(cart_reservation.order_detail.reload.order_status).not_to eq(canceled_status)
    end

    context "with cancellation fee" do
      before :each do
        instrument.price_policies.first.update(cancellation_cost: 10)
      end

      it "should charge the fee" do
        canceler.cancel_reservations
        expect(past_reservation.order_detail.reload.actual_cost.to_f).to eq(10)
      end
    end

  end

  context "without auto-cancel minutes" do
    before :each do
      instrument.update(auto_cancel_mins: 0)
    end

    it "should not cancel reservations" do
      canceler.cancel_reservations
      expect(past_reservation.order_detail.order_status).not_to eq canceled_status
    end
  end
end
