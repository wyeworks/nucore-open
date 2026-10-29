# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminReservationExpirer do
  let(:expirer) { AdminReservationExpirer.new }
  let(:instrument) { create(:setup_instrument) }
  let!(:expired_admin_reservation) { create(:admin_reservation, expires_mins_before: 60, reserve_start_at: 59.minutes.from_now, product: instrument) }
  let!(:very_expired_admin_reservation) { create(:admin_reservation, expires_mins_before: 48 * 60, reserve_start_at: (48 * 60 - 1).minutes.from_now, product: instrument) }
  let!(:unexpired_admin_reservation) { create(:admin_reservation, expires_mins_before: 10, reserve_start_at: 11.minutes.from_now, product: instrument) }
  let!(:never_expires_admin_reservation) { create(:admin_reservation, expires_mins_before: nil, reserve_start_at: 1.hour.ago, product: instrument) }

  describe "#expire!" do
    it "soft-deletes reservation expiring one hour before" do
      expirer.expire!
      expect(expired_admin_reservation.reload).to be_paranoia_destroyed
    end

    it "soft-deletes reservation expiring two days before" do
      expirer.expire!
      expect(very_expired_admin_reservation.reload).to be_paranoia_destroyed
    end

    it "does not delete unexpired reservations" do
      expirer.expire!
      expect(unexpired_admin_reservation.reload).not_to be_paranoia_destroyed
    end

    it "does not delete reservations with no expires_mins_before set" do
      expirer.expire!
      expect(never_expires_admin_reservation.reload).not_to be_paranoia_destroyed
    end
  end
end
