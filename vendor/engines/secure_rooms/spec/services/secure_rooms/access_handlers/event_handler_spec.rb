# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessHandlers::EventHandler, type: :service do
  let(:user) { create :user, card_number: "user_456789" }
  let(:card_reader) { create :card_reader }
  let(:card_number) { "123456" }

  describe "#process" do
    context "with access denial verdict" do
      let(:verdict) do
        SecureRooms::AccessRules::Verdict.new(:deny, :no_accounts, user, card_reader)
      end

      it "creates an Event" do
        expect { described_class.process(verdict) }
          .to change(SecureRooms::Event, :count).by(1)
      end

      describe "resulting Event" do
        subject(:event) { described_class.process(verdict) }

        it "stores the user and reader and card_number of the user" do
          expect(event.card_reader).to eq card_reader
          expect(event.user).to eq user
          expect(event.card_number).to eq user.card_number
        end
      end
    end

    context "when the verdict does not have a user" do
      let(:verdict) do
        SecureRooms::AccessRules::Verdict.new(:deny, :user_not_found, nil, card_reader, card_number:)
      end

      describe "resulting Event" do
        subject(:event) { described_class.process(verdict) }

        it "stores the card_number attempted" do
          expect(event.card_number).to eq card_number
        end
      end
    end

    context "with access granted verdict" do
      let(:accounts) { create_list(:account, 3, :with_account_owner, owner: user) }
      let(:selected_account) { accounts.first }

      let(:verdict) do
        SecureRooms::AccessRules::Verdict.new(
          :grant,
          :selected_account,
          user,
          card_reader,
          accounts:,
          selected_account:,
        )
      end

      describe "resulting Event" do
        subject(:event) { described_class.process(verdict) }

        it "stores the account used" do
          expect(event.account).to eq selected_account
        end
      end
    end
  end
end
