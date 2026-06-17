# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductNotifications::SlotAvailableService do
  let(:product) { create(:setup_instrument) }
  let(:facility) { product.facility }

  let(:start_time) { 1.day.from_now }
  let(:end_time) { start_time + 30.minutes }

  subject { described_class.new(product, start_time, end_time) }

  context "when product notification slot available no set" do
    it "does not call the mailer" do
      expect(ProductNotificationMailer).not_to receive(:slot_available)

      subject.notify!
    end
  end

  context "when product notification slot available set" do
    let(:some_user) { create(:user) }
    let(:reservation_user) { create(:user) }
    let(:product_notification) do
      ProductNotification.create!(
        facility:,
        notification_type: :slot_available,
      )
    end

    before do
      create(:purchased_reservation, product:, user: reservation_user)

      product_notification.products << product
      product_notification.users << [some_user, reservation_user]
    end

    it "notifies some user from upcoming reservations" do
      expect { subject.notify! }.to(
        have_enqueued_mail(
          ProductNotificationMailer,
          :slot_available,
        ).with(product, some_user, start_time, end_time, subject: nil)
      )
    end

    it "notifies reservation user from upcoming reservations" do
      expect { subject.notify! }.to(
        have_enqueued_mail(
          ProductNotificationMailer,
          :slot_available,
        ).with(product, reservation_user, start_time, end_time, subject: nil)
      )
    end

    it "enqueues exactly two emails" do
      expect { subject.notify! }.to(
        have_enqueued_mail(ProductNotificationMailer, :slot_available).exactly(2)
      )
    end

    context "when email subject is specified" do
      let(:email_subject) { "Some subject" }

      before do
        product_notification.update(email_subject:)
      end

      it "pass the subject to the mailer" do
        expect { subject.notify! }.to(
          have_enqueued_mail(
            ProductNotificationMailer,
            :slot_available,
          ).with(product, some_user, start_time, end_time, subject: email_subject)
        )
      end
    end

    context "when upcoming reservation user excluded" do
      subject do
        described_class.new(
          product, start_time, end_time,
          exclude_user: reservation_user,
        )
      end

      it "notifies some_user" do
        expect { subject.notify! }.to(
          have_enqueued_mail(
            ProductNotificationMailer,
            :slot_available,
          ).with(product, some_user, start_time, end_time, subject: nil)
        )
      end

      it "enqueue one email" do
        expect { subject.notify! }.to(
          have_enqueued_mail(ProductNotificationMailer, :slot_available).exactly(1)
        )
      end
    end
  end
end
