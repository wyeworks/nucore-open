# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutoExpireReservation, :time_travel do
  let(:now) { Time.zone.now.change(hour: 9, min: 31) }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:instrument) { create(:setup_instrument, :timer, min_reserve_mins: 1, problems_resolvable_by_user: true) }

  describe "#perform" do
    context "a started reservation" do
      let!(:reservation) do
        create(:purchased_reservation, :yesterday, actual_start_at: 1.hour.ago,
                                                   product: instrument)
      end

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
        reservation.reload
      end

      it "completes the reservation" do
        expect { action.perform }.to change { order_detail.reload.state }.from("new").to("complete")
      end

      it "sets this to a problem reservation" do
        expect { action.perform }.to change { order_detail.reload.problem }.to(true)
      end

      it "logs the problem reservation" do
        action.perform
        log_event = LogEvent.find_by(loggable: reservation.order_detail, event_type: :problem_queue)
        expect(log_event).to be_present
        expect(log_event.metadata).to eq("cause"=>"auto_expire")
      end

      it "does not assign pricing" do
        action.perform
        expect(order_detail.reload.price_policy).to be_nil
      end

      it "sets the reservation fulfilled at time" do
        expect { action.perform }.to change { order_detail.reload.fulfilled_at }.to(reservation.reserve_end_at)
      end

      it "triggers an email with resolution options" do
        expect { action.perform }.to enqueue_mail(ProblemOrderMailer, :notify_user_with_resolution_option)
      end
    end

    context "a started Nonbillable reservation" do
      let(:instrument) { create(:setup_instrument, :timer, min_reserve_mins: 1, problems_resolvable_by_user: true, billing_mode: "Nonbillable") }

      let!(:reservation) do
        create(:purchased_reservation, :yesterday, actual_start_at: 1.hour.ago,
                                                   product: instrument)
      end

      it "completes the reservation" do
        expect { action.perform }.to change { order_detail.reload.state }.from("new").to("complete")
      end

      it "sets this to a problem reservation" do
        expect { action.perform }.to change { order_detail.reload.problem }.to(true)
      end

      it "logs the problem reservation" do
        action.perform
        log_event = LogEvent.find_by(loggable: reservation.order_detail, event_type: :problem_queue)
        expect(log_event).to be_present
        expect(log_event.metadata).to eq("cause"=>"auto_expire")
      end

      it "assigns a price policy" do
        action.perform
        expect(order_detail.reload.price_policy).to be_present
        expect(order_detail.reload.price_policy.unit_cost).to eq 0
      end

      it "sets the reservation fulfilled at time" do
        expect { action.perform }.to change { order_detail.reload.fulfilled_at }.to(reservation.reserve_end_at)
      end

      it "triggers an email with resolution options" do
        expect { action.perform }.to enqueue_mail(ProblemOrderMailer, :notify_user_with_resolution_option)
      end
    end

    context "a started reservation that is already in the problem queue" do
      let!(:reservation) do
        create(:purchased_reservation, :yesterday, actual_start_at: 1.hour.ago,
                                                   product: instrument)
      end

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product

        reservation.actual_end_at = nil
        reservation.order_detail.complete!
        expect(reservation.order_detail).to be_problem
      end

      it "does not trigger an email" do
        expect { action.perform }.not_to enqueue_mail
      end
    end

    context "an unpurchased reservation" do
      let!(:reservation) do
        create(:setup_reservation, :yesterday, actual_start_at: 1.hour.ago,
                                               product: instrument)
      end

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
        reservation.reload

        action.perform
        order_detail.reload
        reservation.reload
      end

      include_examples "it does not complete order" do
        it "leaves order status nil" do
          expect(reservation.actual_end_at).to be_nil
        end

        it "leaves order status nil" do
          expect(order_detail.order_status).to eq(nil)
        end
      end
    end

    context "a reservation which has not passed the end time" do
      let!(:reservation) do
        start_at = 30.minutes.ago
        end_at = 1.minute.from_now

        create(:purchased_reservation,
               product: instrument,
               actual_start_at: 30.minutes.ago,
               reserve_start_at: start_at,
               reserve_end_at: end_at)
      end

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
        reservation.reload

        action.perform
        order_detail.reload
        reservation.reload
      end

      include_examples "it does not complete order" do
        it "leaves order status nil" do
          expect(reservation.actual_end_at).to be_nil
        end

        it "leaves order status nil" do
          expect(order_detail.order_status.name).to eq("New")
        end
      end
    end

    context "a reservation only reservation" do
      let!(:reservation) do
        create(:purchased_reservation, :yesterday,
               product: create(:setup_instrument, min_reserve_mins: 1))
      end

      before do
        reservation.reload

        action.perform
        order_detail.reload
        reservation.reload
      end

      include_examples "it does not complete order" do
        it "leaves order status nil" do
          expect(reservation.actual_end_at).to be_nil
        end

        it "leaves order status nil" do
          expect(order_detail.order_status.name).to eq("New")
        end
      end
    end

    context "a past reservation which is unstarted" do
      let!(:reservation) { create(:purchased_reservation, :yesterday, product: instrument) }

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
        reservation.reload
      end

      it "completes the reservation" do
        expect { action.perform }.to change { order_detail.reload.state }.from("new").to("complete")
      end

      it "sets this to a problem reservation" do
        expect { action.perform }.to change { order_detail.reload.problem }.to(true)
      end

      it "does not assign pricing" do
        action.perform
        expect(order_detail.reload.price_policy).to be_nil
      end

      it "sets the reservation fulfilled at time" do
        expect { action.perform }.to change { order_detail.reload.fulfilled_at }.to(reservation.reserve_end_at)
      end

      it "triggers a notification email" do
        expect { action.perform }.to enqueue_mail(ProblemOrderMailer, :notify_user)
      end
    end

    context "a future reservation which is unstarted" do
      let!(:reservation) { create(:purchased_reservation, :later_today, product: instrument) }

      before do
        reservation.product.price_policies.destroy_all
        create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
        reservation.reload
      end

      include_examples "it does not complete order" do
        it "leaves order status nil" do
          expect(reservation.actual_end_at).to be_nil
        end

        it "leaves order status nil" do
          expect(order_detail.order_status.name).to eq("New")
        end
      end
    end
  end
end
