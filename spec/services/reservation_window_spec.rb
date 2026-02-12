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
end
