# frozen_string_literal: true

require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe SplitAccounts::SplitAccountBuilder, :enable_split_accounts do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build" do
    let(:account) { builder.build }
    let(:splits) { account.splits }

    let(:options) do
      {
        account_type: "SplitAccounts::SplitAccount",
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        current_user: build_stubbed(:user),
        params:,
      }
    end

    describe "happy path" do
      let(:params) do
        ActionController::Parameters.new(
          split_accounts_split_account: {
            splits_attributes: {
              "0" => {
                subaccount_id: subaccount_2.id,
                percent: 50,
                apply_remainder: true,
              },
              "1" => {
                subaccount_id: subaccount_1.id,
                percent: 50,
                apply_remainder: false,
              },
            },
          },
        )
      end

      let(:subaccount_1) { create(:setup_account, expires_at: 1.month.from_now.change(usec: 0)) }
      let(:subaccount_2) { create(:setup_account, expires_at: 2.months.from_now.change(usec: 0)) }

      it "is a split account" do
        expect(account).to be_a SplitAccounts::SplitAccount
      end

      it "sets splits" do
        expect(splits.size).to be(2)
      end

      it "sets expired_at to earliest expiring subaccount" do
        expect(account.expires_at).to eq(subaccount_1.expires_at)
      end
    end

    describe "with a blank subaccount" do
      let(:params) do
        ActionController::Parameters.new(
          split_accounts_split_account: {
            splits_attributes: {
              "0" => {
                subaccount_id: "",
                percent: 100,
                apply_remainder: true,
              },
            },
          },
        )
      end

      it "does not error" do
        expect(splits).to be_one
      end
    end

    describe "with no subaccounts" do
      let(:params) { {} }

      it "has two default subaccounts" do
        expect(splits.size).to eq(2)
      end

      it "sets them all to 50%" do
        expect(splits.map(&:percent)).to all(eq(50))
      end

      it "sets the first one, and only the first one to apply_remainder" do
        expect(splits.first).to be_apply_remainder
        expect(splits.second).not_to be_apply_remainder
      end
    end
  end
end
