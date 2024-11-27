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
        email: order.user.email
      )
    end
  end

  context "with an offline reservation" do
    let(:reservation) { build(:offline_reservation, product:) }

    it { is_expected.to include(:id, :product, :title, :start, :end) }
    it { is_expected.to include(className: "unavailable") }
    it { expect(presenter).to be_a(Reservations::OfflineCalendarPresenter) }
  end

  context "with an admin hold reservation" do
    let(:reservation) { build(:admin_reservation, product:) }

    it { is_expected.to include(:id, :product, :title, :start, :end) }
    it { is_expected.to include(className: "unavailable") }
    it { expect(presenter).to be_a(Reservations::FallbackCalendarPresenter) }

    context "when expires_mins_before is present" do
      before do
        reservation.expires_mins_before = 30
      end

      it { is_expected.to include(expiration: String) }
    end
  end
end
