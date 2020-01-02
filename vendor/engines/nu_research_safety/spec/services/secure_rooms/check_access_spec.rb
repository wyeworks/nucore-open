# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::CheckAccess, type: :service do
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price) }
  let(:card_reader) { build(:card_reader, secure_room: secure_room) }
  let(:certificate) do
    create(:certificate).tap { |c| c.products << secure_room }
  end

  subject(:verdict) { described_class.new.authorize(card_user, card_reader) }

  describe "a facility operator who does not have the certification" do
    let(:card_user) { create(:user, :staff, facility: secure_room.facility) }

    it { is_expected.to be_granted }

    it "does not hit the certification api" do
      expect(NuResearchSafety::CertificationLookup).not_to receive(:certified?)
    end
  end

  describe "a normal user" do
    let(:card_user) { create(:user) }
    let!(:account) { create(:nufs_account, :with_account_owner, owner: card_user) }
    before { secure_room.product_users.create!(user: card_user, approved_by: 0) }

    describe "who has certification" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(card_user, certificate).and_return(true)
      end

      it { is_expected.to be_pending }
    end

    describe "who does not have the certification" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(card_user, certificate).and_return(false)
      end

      it "is denied for not having a certificaiton" do
        expect(verdict).to be_denied
        expect(verdict.reason).to include("Research Safety Certification")
      end
    end

    describe "who is leaving the room" do
      let(:card_reader) { build(:card_reader, :exit, secure_room: secure_room) }

      it "does not check the api and is granted" do
        expect(NuResearchSafety::CertificationLookup).not_to receive(:certified?)
        expect(verdict).to be_granted
      end
    end
  end
end
