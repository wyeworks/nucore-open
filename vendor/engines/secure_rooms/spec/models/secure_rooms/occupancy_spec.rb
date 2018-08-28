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
  end
end
