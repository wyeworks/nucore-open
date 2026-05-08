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
    let(:access_list_user) { create(:user) }
    let(:reservation_user) { create(:user) }

    before do
      create(:product_user, product:, user: access_list_user)
      create(:purchased_reservation, product:, user: reservation_user)

      product.create_product_notification!(
        product:,
        notification_type: :slot_available,
        recipient_source:,
      )
    end

    context "when recipients taken from access list" do
      let(:recipient_source) { :access_list }

      it "notifies users from access list" do
        expect { subject.notify! }.to(
          have_enqueued_mail(
            ProductNotificationMailer,
            :slot_available,
          ).with(product, access_list_user, start_time, end_time)
        )
      end

      it "enqueues exactly one email" do
        expect { subject.notify! }.to(
          have_enqueued_mail(ProductNotificationMailer, :slot_available).exactly(1)
        )
      end
    end

    context "when recipients taken from reservations" do
      let(:recipient_source) { :reservations }

      it "notifies users from upcoming reservations" do
        expect { subject.notify! }.to(
          have_enqueued_mail(
            ProductNotificationMailer,
            :slot_available,
          ).with(product, reservation_user, start_time, end_time)
        )
      end

      it "enqueues exactly one email" do
        expect { subject.notify! }.to(
          have_enqueued_mail(ProductNotificationMailer, :slot_available).exactly(1)
        )
      end

      context "when upcoming reservation user excluded" do
        subject do
          described_class.new(
            product, start_time, end_time,
            exclude_user: reservation_user,
          )
        end

        it "notifies no one" do
          expect { subject.notify! }.not_to enqueue_mail
        end
      end
    end
  end
end
