# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationWindow do
  describe "max_window" do
    let(:instrument) { create(:setup_instrument) }
    let(:reservation) { create(:reservation, product: instrument) }
    let(:instance) do
      described_class.new(reservation, create(:user))
    end

    it "takes price groups from product and not order detail" do
      expect(reservation.order_detail).not_to receive(:price_groups)
      expect(instrument).to receive(:price_groups)

      instance.max_window
    end
  end

  describe "operator window" do
    let(:instrument) { create(:setup_instrument) }
    let(:reservation) { create(:reservation, product: instrument) }
    let(:instance) { described_class.new(reservation, user) }

    context "when user is facility staff" do
      let(:user) { create(:user, :staff, facility: instrument.facility) }

      it "gets the operator window" do
        expect(instance.max_window).to eq(365)
        expect(instance.max_days_ago).to eq(-365)
      end
    end

    context "when user has order management granular permission", feature_setting: { granular_permissions: true } do
      let(:user) { create(:user) }

      before do
        create(:facility_user_permission, user:, facility: instrument.facility, order_management: true)
      end

      it "gets the operator window" do
        expect(instance.max_window).to eq(365)
        expect(instance.max_days_ago).to eq(-365)
      end
    end

    context "when user has no roles or permissions" do
      let(:user) { create(:user) }

      it "gets the end user window" do
        expect(instance.max_days_ago).to eq(0)
      end
    end
  end
end
