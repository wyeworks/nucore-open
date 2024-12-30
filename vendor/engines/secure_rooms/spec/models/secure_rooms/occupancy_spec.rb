# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::Occupancy do
  it { is_expected.to validate_presence_of :secure_room }
  it { is_expected.to validate_presence_of :user }

  let(:occupancy) { build :occupancy }

  describe "#problem_description_key" do
    subject(:problem_description_key) { occupancy.problem_description_key }

    context "entry_at.blank?" do
      before { expect(occupancy).to receive(:entry_at).and_return(nil) }

      it { is_expected.to eq :missing_entry }
    end

    context "exit_at.blank?" do
      before do
        expect(occupancy).to receive(:entry_at).and_return(Time.current)
        expect(occupancy).to receive(:exit_at).and_return(nil)
      end

      it { is_expected.to eq :missing_exit }
    end

    context "0 min actual duration" do
      before do
        now = Time.current
        occupancy.entry_at = now
        occupancy.exit_at = now
      end

      context "with an entry event" do
        before { occupancy.entry_event = SecureRooms::Event.new }

        it { is_expected.to eq :missing_exit }
      end

      context "with an exit event" do
        before { occupancy.exit_event = SecureRooms::Event.new }

        it { is_expected.to eq :missing_entry }
      end
    end
  end

  describe "duration validation" do
    context "when it's positive" do
      before do
        occupancy.entry_at = 5.minutes.ago
        occupancy.exit_at = 1.minute.ago
      end

      it "is valid" do
        expect(occupancy.entry_at).to be < occupancy.exit_at
        expect(occupancy).to be_valid
      end
    end

    context "when it's zero" do
      before do
        allow(occupancy).to receive(:editing_time_data).and_return(true)
        now = Time.current
        occupancy.entry_at = now
        occupancy.exit_at = now
        occupancy.valid?
      end

      it "adds duration error" do
        expect(occupancy.errors).to be_added(:actual_duration_mins, :zero_minutes)
        expect(occupancy.errors[:actual_duration_mins]).to(
          include("must be at least 1 minute")
        )
      end
    end
  end
end
