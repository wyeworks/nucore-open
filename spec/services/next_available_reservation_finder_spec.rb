require "spec_helper"

RSpec.describe NextAvailableReservationFinder do
  let(:instrument) { FactoryBot.build(:instrument, min_reserve_mins: 0) }
  let(:user) { FactoryBot.build(:user) }

  describe "#next_available_for" do
    describe "without a next available reservation" do
      subject(:reservation) { described_class.new(instrument).next_available_for(user, user) }

      before do
        expect(instrument).to receive(:next_available_reservation).and_return(nil)
      end

      it "has a reservation starting around now" do
        expect(reservation.reserve_start_at).to be_within(1.minute).of(Time.current)
      end

      it "is thirty minutes long" do
        expect(reservation.duration_mins).to eq(30)
      end

      it "is on the right product" do
        expect(reservation.product).to eq(instrument)
      end
    end
  end
end
