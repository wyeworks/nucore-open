# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutoEndPreviousReservation do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :timer, facility: facility) }
  let(:current_user) { create(:user) }
  let(:previous_user) { create(:user) }

  describe "#end_previous_reservations!" do
    subject { described_class.new(instrument, current_user).end_previous_reservations! }

    context "when feature flag is enabled", feature_setting: { auto_end_reservations_on_next_start: true } do
      context "with a timer-based instrument" do
        let!(:previous_reservation) do
          reservation = build(:purchased_reservation,
                              product: instrument,
                              user: previous_user,
                              reserve_start_at: 2.hours.ago,
                              reserve_end_at: 1.hour.ago,
                              actual_start_at: 2.hours.ago,
                              actual_end_at: nil)
          reservation.save!(validate: false)
          reservation
        end

        it "ends the previous reservation" do
          expect do
            subject
          end.to change { previous_reservation.reload.actual_end_at }.from(nil)
        end

        it "completes the order detail" do
          expect do
            subject
          end.to change { previous_reservation.order_detail.reload.state }.to("complete")
        end

        it "sends notification email" do
          expect do
            subject
          end.to enqueue_mail(AutoEndReservationMailer, :notify_auto_ended)
        end

        it "logs the auto-end event" do
          subject

          log_event = LogEvent.find_by(
            loggable: previous_reservation.order_detail,
            event_type: :auto_ended_by_next_reservation,
            user: current_user
          )

          expect(log_event).to be_present
          expect(log_event.metadata).to eq("cause" => "auto_end_on_next_start")
        end

        context "when previous reservation is already ended" do
          before { previous_reservation.update_column(:actual_end_at, 30.minutes.ago) }

          it "does not modify the reservation" do
            expect do
              subject
            end.not_to change { previous_reservation.reload.actual_end_at }
          end
        end

        context "when previous reservation is canceled" do
          before { previous_reservation.order_detail.update_column(:canceled_at, 1.hour.ago) }

          it "does not modify the reservation" do
            expect do
              subject
            end.not_to change { previous_reservation.reload.actual_end_at }
          end
        end

        context "when previous reservation started more than 12 hours ago" do
          before { previous_reservation.update_column(:actual_start_at, 13.hours.ago) }

          it "does not modify the reservation" do
            expect do
              subject
            end.not_to change { previous_reservation.reload.actual_end_at }
          end

          it "does not send notification email" do
            expect do
              subject
            end.not_to enqueue_mail
          end
        end
      end

      context "when feature flag is disabled", feature_setting: { auto_end_reservations_on_next_start: false } do
        it "does not end previous reservations" do
          expect do
            subject
          end.not_to enqueue_mail
        end
      end
    end
  end
end
