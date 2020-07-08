# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutoLogout, :time_travel do
  let(:now) { Time.zone.now.change(hour: 9, min: 31) }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:relay) { build_stubbed(:relay, auto_logout: true, auto_logout_minutes: 10) }

  shared_context "all instruments return a relay" do
    before { allow_any_instance_of(Instrument).to receive(:relay).and_return relay }
  end

  describe "a started reservation past log out time" do
    let!(:reservation) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }

    include_context "all instruments return a relay"

    before do
      allow_any_instance_of(Instrument).to receive(:relay).and_return relay

      reservation.product.price_policies.destroy_all
      create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
      reservation.reload

      expect(relay).to receive(:deactivate)
    end

    it "completes the reservation" do
      expect { action.perform }.to change { order_detail.reload.state }.from("new").to("complete")
    end

    it "does not set the reservation actual end at" do
      expect { action.perform }.to_not change { order_detail.reservation.reload.actual_end_at }.from(nil)
    end

    it "does not set the reservation price policy" do
      expect { action.perform }.to_not change { order_detail.reload.price_policy }.from(nil)
    end

    it "is a problem order" do
      expect { action.perform }.to change { order_detail.reload.problem_order? }.to(true)
    end

    it "deactivates the relay" do
      # see before block for deactivate expectation
      action.perform
    end

    it "triggers an email" do
      expect { action.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  describe "a new reservation prior to log out time" do
    let!(:reservation) do
      start_at = 30.minutes.ago # 9:01am
      end_at = 1.minute.ago # 9:30am

      # Auto-logout is at 9:40

      create(:purchased_reservation,
             product: create(:setup_instrument, min_reserve_mins: 1),
             actual_start_at: 30.minutes.ago,
             reserve_start_at: start_at,
             reserve_end_at: end_at)
    end

    include_context "all instruments return a relay"

    before do
      expect(relay).to_not receive(:deactivate)

      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples "it does not complete order"

    it "does not deactivate the relay" do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe "a running new reservation" do
    let!(:reservation) { create(:purchased_reservation, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    include_context "all instruments return a relay"

    before do
      expect(relay).to_not receive(:deactivate)

      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples "it does not complete order"

    it "does not deactivate the relay" do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe "an unpurchased reservation" do
    let!(:reservation) { create(:setup_reservation, :yesterday) }

    include_context "all instruments return a relay"

    before do
      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples "it does not complete order"
  end

  describe "the following running reservation" do
    let!(:reservation_done) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }
    let!(:reservation_running) { create(:purchased_reservation, product: reservation_done.product, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    include_context "all instruments return a relay"

    before do
      expect(relay).to_not receive(:deactivate)
    end

    it "does not deactivate the relay" do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe "ignores other problem reservations" do
    let!(:product) { create(:setup_instrument, min_reserve_mins: 1) }
    let!(:reservation_problem) { create(:purchased_reservation, :yesterday, product: product, actual_start_at: 1.day.ago, actual_end_at: nil) }
    let!(:reservation_running) { create(:purchased_reservation, product: product, reserve_start_at: 30. minutes.ago, reserve_end_at: 11.minutes.ago, actual_start_at: 30.minutes.ago) }

    include_context "all instruments return a relay"

    before do
      reservation_problem.complete!
      expect(relay).to receive(:deactivate)
    end

    it "deactivates the relay" do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe "two reservations with unique instruments sharing a calendar" do
    let!(:shared_instrument_1) { create(:setup_instrument, min_reserve_mins: 1, relay: build(:relay_syna, auto_logout: true)) }
    let!(:shared_instrument_2) { create(:setup_instrument, min_reserve_mins: 1, schedule: shared_instrument_1.schedule, relay: build(:relay_syna, auto_logout: true)) }
    let!(:reservation_done) { create(:purchased_reservation, :yesterday, product: shared_instrument_1, actual_start_at: 1.day.ago) }
    let!(:reservation_running) { create(:purchased_reservation, product: shared_instrument_2, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    it "does not deactivate the relay" do
      expect(shared_instrument_1.relay).to_not receive(:deactivate)
      expect(shared_instrument_2.relay).to_not receive(:deactivate)

      action.perform
    end
  end
end
