# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instruments::AvailabilityStatus do
  subject(:status) { described_class.new(instrument.facility) }

  let(:instrument) { create(:setup_instrument) }

  describe "#available_now?" do
    it "is true when open now with no current reservation" do
      expect(status.available_now?(instrument)).to be true
    end

    context "with a current reservation" do
      before do
        create(:purchased_reservation,
               reserve_start_at: 30.minutes.ago,
               reserve_end_at: 30.minutes.from_now,
               product: instrument)
      end

      it "is false" do
        expect(status.available_now?(instrument)).to be false
      end
    end

    context "with a current reservation on a schedule-sharing sibling" do
      before do
        sibling = create(:setup_instrument,
                         facility: instrument.facility,
                         schedule: instrument.schedule)
        create(:admin_reservation,
               reserve_start_at: 30.minutes.ago,
               reserve_end_at: 30.minutes.from_now,
               product: sibling)
      end

      it "is false because the shared schedule is in use" do
        expect(status.available_now?(instrument)).to be false
      end
    end

    context "when closed now (no schedule rule covers the current time)" do
      before { instrument.schedule_rules.destroy_all }

      it "is false" do
        expect(status.available_now?(instrument)).to be false
      end
    end

    context "on a holiday" do
      before { Holiday.create!(date: Time.current.to_date) }

      it "is false when the instrument restricts holiday access" do
        instrument.update!(restrict_holiday_access: true)
        expect(status.available_now?(instrument)).to be false
      end

      it "is true when the instrument does not restrict holiday access" do
        instrument.update!(restrict_holiday_access: false)
        expect(status.available_now?(instrument)).to be true
      end
    end
  end
end
