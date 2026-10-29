# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::CalendarPresenter do
  let(:product) { build(:product) }
  let(:presenter) { described_class.build(reservation) }
  let(:subject) { presenter.as_calendar_object }

  context "with an normal reservation with order" do
    let(:reservation) { build(:setup_reservation) }
    let(:order) { reservation.order }

    it { is_expected.to include(:id, :product, :title, :start, :end) }
    it { expect(presenter).to be_a(Reservations::OrderCalendarPresenter) }

    it "include order details if with_details" do
      expect(presenter.as_calendar_object(with_details: true)).to include(
        :orderId,
        :orderNote,
        title: order.user.full_name,
        email: order.user.email,
      )
    end
  end

  context "with a canceled reservation" do
    let(:reservation) { build(:setup_reservation) }

    before { reservation.order_detail.canceled_at = 1.minute.ago }

    it { is_expected.to include(className: ["canceled"]) }

    it "keeps the other-instrument class when discriminating" do
      expect(
        presenter.as_calendar_object(discriminate: true, instrument_id: reservation.product_id + 1),
      ).to include(className: ["other-instrument", "canceled"])
    end
  end

  context "with a normal reservation with order without details" do
    let(:reservation) { build(:setup_reservation) }
    let(:order) { reservation.order }

    it { is_expected.not_to include(:email, :orderId, :orderNote) }
    it { is_expected.not_to include(title: order.user.full_name) }

    it "includes only the owner's name for the owner" do
      calendar_object = presenter.as_calendar_object(user: order.user)

      expect(calendar_object).to include(title: order.user.full_name)
      expect(calendar_object).not_to include(:email, :orderId, :orderNote)
    end

    it "does not include the owner's name for another user" do
      expect(presenter.as_calendar_object(user: build(:user))).not_to include(title: order.user.full_name)
    end
  end

  context "with an offline reservation" do
    let(:creator) { build(:user) }
    let(:reservation) { build(:offline_reservation, product:, created_by: creator) }

    it { is_expected.to include(:id, :product, :title, :start, :end) }
    it { is_expected.to include(className: "unavailable") }
    it { is_expected.not_to include(:email) }
    it { expect(presenter).to be_a(Reservations::OfflineCalendarPresenter) }

    it "includes the creator's name if with_details" do
      expect(presenter.as_calendar_object(with_details: true)).to include(email: creator.full_name)
    end
  end

  context "with an admin hold reservation" do
    let(:creator) { build(:user) }
    let(:reservation) { build(:admin_reservation, product:, created_by: creator, user_note: "Maintenance") }

    it { is_expected.to include(:id, :product, :title, :start, :end) }
    it { is_expected.to include(className: "unavailable") }
    it { is_expected.to include(userNote: "Maintenance") }
    it { is_expected.not_to include(:email) }
    it { expect(presenter).to be_a(Reservations::FallbackCalendarPresenter) }

    it "includes the creator's name if with_details" do
      expect(presenter.as_calendar_object(with_details: true)).to include(email: creator.full_name)
    end

    context "when expires_mins_before is present" do
      before do
        reservation.expires_mins_before = 30
      end

      it { is_expected.to include(expiration: String) }
    end
  end
end
