# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemNotificationSender do
  let(:facility) { create(:setup_facility) }
  let(:current_user) { create(:user, :facility_director, facility:) }

  let(:resolvable_instrument) do
    create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility:, problems_resolvable_by_user: true)
  end
  let(:non_resolvable_instrument) do
    create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility:, problems_resolvable_by_user: false)
  end

  let!(:resolvable_order_detail) { problem_order_detail_for(resolvable_instrument) }
  let!(:non_resolvable_order_detail) { problem_order_detail_for(non_resolvable_instrument) }

  let(:order_details) { OrderDetail.where(id: [resolvable_order_detail, non_resolvable_order_detail]) }

  subject(:sender) { described_class.new(order_details, current_user, notification_groups:) }

  def problem_order_detail_for(instrument)
    reservation = create(
      :purchased_reservation,
      product: instrument,
      reserve_start_at: 2.hours.ago,
      reserve_end_at: 1.hour.ago,
      actual_start_at: 1.hour.ago,
      actual_end_at: nil,
    )
    MoveToProblemQueue.move!(reservation.order_detail, cause: :reservation_started)
    reservation.order_detail.reload
  end

  def bulk_notification_events
    LogEvent.where(event_type: :bulk_problem_notification)
  end

  it "sets up one resolvable and one non-resolvable problem order detail" do
    expect(OrderDetails::ProblemResolutionPolicy.new(resolvable_order_detail)).to be_user_can_resolve
    expect(OrderDetails::ProblemResolutionPolicy.new(non_resolvable_order_detail)).not_to be_user_can_resolve
  end

  describe "#send_notifications" do
    context "with only the resolvable group selected" do
      let(:notification_groups) { [:resolvable] }

      it "emails only the resolvable order detail" do
        expect { sender.send_notifications }
          .to have_enqueued_mail(ProblemOrderMailer, :notify_user_with_resolution_option)
          .with(resolvable_order_detail).once
      end

      it "does not email the non-resolvable order detail" do
        expect { sender.send_notifications }
          .not_to have_enqueued_mail(ProblemOrderMailer, :notify_user)
      end

      it "returns the number of emails queued" do
        expect(sender.send_notifications).to eq(1)
      end

      it "logs only the order detail it queued" do
        sender.send_notifications

        expect(bulk_notification_events.count).to eq(1)
        expect(bulk_notification_events.first.metadata["order_detail_ids"])
          .to eq(resolvable_order_detail.id.to_s)
      end
    end

    context "with only the non-resolvable group selected" do
      let(:notification_groups) { [:non_resolvable] }

      it "emails only the non-resolvable order detail" do
        expect { sender.send_notifications }
          .to have_enqueued_mail(ProblemOrderMailer, :notify_user)
          .with(non_resolvable_order_detail).once
      end

      it "does not email the resolvable order detail" do
        expect { sender.send_notifications }
          .not_to have_enqueued_mail(ProblemOrderMailer, :notify_user_with_resolution_option)
      end

      it "logs only the order detail it queued" do
        sender.send_notifications

        expect(bulk_notification_events.count).to eq(1)
        expect(bulk_notification_events.first.metadata["order_detail_ids"])
          .to eq(non_resolvable_order_detail.id.to_s)
      end
    end

    context "with both groups selected" do
      let(:notification_groups) { [:resolvable, :non_resolvable] }

      it "sends each order detail exactly one email" do
        expect { sender.send_notifications }
          .to have_enqueued_mail(ProblemOrderMailer, :notify_user_with_resolution_option).once
          .and have_enqueued_mail(ProblemOrderMailer, :notify_user).once
      end

      it "returns the number of emails queued" do
        expect(sender.send_notifications).to eq(2)
      end

      it "logs one event per notified user" do
        sender.send_notifications

        expect(bulk_notification_events.map(&:loggable))
          .to match_array([resolvable_order_detail.user, non_resolvable_order_detail.user])
        expect(bulk_notification_events.map(&:user)).to all(eq(current_user))
      end

      context "when both order details belong to the same user" do
        let(:shared_user) { create(:user) }

        before do
          [resolvable_order_detail, non_resolvable_order_detail].each do |order_detail|
            order_detail.order.update_columns(user_id: shared_user.id)
          end
        end

        it "logs a single event listing both order detail ids" do
          sender.send_notifications

          expect(bulk_notification_events.count).to eq(1)
          expect(bulk_notification_events.first.loggable).to eq(shared_user)
          expect(bulk_notification_events.first.metadata["order_detail_ids"].split(", "))
            .to match_array([resolvable_order_detail.id.to_s, non_resolvable_order_detail.id.to_s])
        end
      end
    end

  end

  describe "#detailed_notification_count" do
    context "with only the resolvable group selected" do
      let(:notification_groups) { [:resolvable] }

      it "counts only the resolvable order detail" do
        expect(sender.detailed_notification_count).to eq(emails: 1, users: 1)
      end
    end

    context "with only the non-resolvable group selected" do
      let(:notification_groups) { [:non_resolvable] }

      it "counts only the non-resolvable order detail" do
        expect(sender.detailed_notification_count).to eq(emails: 1, users: 1)
      end
    end

    context "with both groups selected" do
      let(:notification_groups) { [:resolvable, :non_resolvable] }

      it "counts every order detail and every user" do
        expect(sender.detailed_notification_count).to eq(emails: 2, users: 2)
      end

      context "when both order details belong to the same user" do
        let(:shared_user) { create(:user) }

        before do
          [resolvable_order_detail, non_resolvable_order_detail].each do |order_detail|
            order_detail.order.update_columns(user_id: shared_user.id)
          end
        end

        it "de-duplicates the user count" do
          expect(sender.detailed_notification_count).to eq(emails: 2, users: 1)
        end
      end
    end

    context "when counting for the confirmation dialog" do
      let(:notification_groups) { [:resolvable, :non_resolvable] }

      it "does not send any email" do
        expect { sender.detailed_notification_count }.not_to have_enqueued_mail(ProblemOrderMailer)
      end
    end
  end
end
