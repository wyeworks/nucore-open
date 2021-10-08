# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject!(:user) { create(:user, :netid, card_number: card_number) }
  let(:card_number) { "abcXYZ" }

  it { is_expected.to validate_uniqueness_of :card_number }
  it { is_expected.to validate_uniqueness_of :i_class_number }

  describe ".for_card_number" do
    context "when user's card number has facility number" do
      let(:card_number) { "12345-123" }

      it "finds the user" do
        expect(described_class.for_card_number(card_number)).to eq(user)
      end
    end

    context "when user's card number has NO facility number" do
      let(:card_number) { "12345" }

      it "finds the user" do
        expect(described_class.for_card_number(card_number)).to eq(user)
      end
    end

    context "when 2 users have the same indala_number" do
      let!(:user2) { create(:user, :netid, card_number: "12345") }
      let(:card_number) { "12345-124" }

      it "finds the user" do
        expect(described_class.for_card_number(card_number)).to eq(user2)
      end
    end
  end
end
