# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfflineReservation do
  subject(:offline_reservation) { instrument.offline_reservations.build }
  let(:instrument) { FactoryBot.create(:setup_instrument) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:admin_note) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:reserve_start_at) }

    it "has one of the designated categories" do
      is_expected
        .to validate_inclusion_of(:category)
        .in_array %w(out_of_order
                     maintenance
                     operator_not_available
                     instrument_not_available
                     other)
    end
  end

  describe "#admin_removable?" do
    it { is_expected.not_to be_admin_removable }
  end

  describe "#end_at_required?" do
    it { is_expected.not_to be_end_at_required }
  end

  describe "#to_s" do
    let(:reserve_start_at) { Time.zone.local(2016, 7, 1, 12, 0) }

    before(:each) do
      allow(subject).to receive(:reserve_start_at) { reserve_start_at }
      allow(subject).to receive(:reserve_end_at) { reserve_end_at }
    end

    context "when the offline event is ongoing" do
      let(:reserve_end_at) { nil }

      it "renders as a range with no known end" do
        expect(subject.to_s).to eq "Fri, 07/01/2016 12:00 PM -"
      end
    end

    context "when the offline event has ended" do
      let(:reserve_end_at) { reserve_start_at + 1.month }

      it "renders as a range with an ending" do
        expect(subject.to_s)
          .to eq "Fri, 07/01/2016 12:00 PM - Mon, 08/01/2016 12:00 PM"
      end
    end
  end

  it "sets billable_minutes to nil before saving" do
    expect(subject).to receive(:billable_minutes=).with(nil)
    subject.run_callbacks(:save) { false }
  end
end
