# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject!(:user) { create(:user, :netid, card_number: card_number) }
  let(:card_number) { "abcXYZ" }


  describe "validations" do
    let!(:other_user) { create(:user, :netid, card_number: "", i_class_number: "") }

    it { is_expected.to validate_uniqueness_of(:card_number).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:i_class_number).case_insensitive }

    it "doesn't error on empty string" do
      expect{ create(:user, :netid, card_number: "", i_class_number: "") }.not_to raise_error
    end
  end

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
      describe "when there is a matching indala number with NO facility code" do
        let!(:user2) { create(:user, :netid, card_number: "12345") }
        let(:card_number) { "12345-123" }

        it "finds the user with matching indala number and no facility code" do
          expect(described_class.for_card_number("12345-789")).to eq(user2)
        end
      end

      describe "when there is a matching indala number with non-matching facility code" do
        let!(:user2) { create(:user, :netid, card_number: "12345-456") }
        let(:card_number) { "12345-123" }

        it "deos not find a user" do
          expect(described_class.for_card_number("12345-789")).to eq(nil)
        end
      end

      describe "when there is an exact match" do
        let!(:user2) { create(:user, :netid, card_number: "12345") }
        let(:card_number) { "12345-124" }

        it "finds the matching user" do
          expect(described_class.for_card_number(card_number)).to eq(user)
        end
      end

    end
  end
end
