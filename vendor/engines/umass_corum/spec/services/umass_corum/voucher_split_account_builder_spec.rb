# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::VoucherSplitAccountBuilder, :enable_split_accounts do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build" do
    let(:account) { builder.build }
    let(:splits) { account.splits }

    let(:options) do
      {
        account_type: "UmassCorum::VoucherSplitAccount",
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        current_user: build_stubbed(:user),
        params: params,
      }
    end

    describe "happy path" do
      let(:params) do
        ActionController::Parameters.new(
          voucher_split_account: {
            account_number: "123123",
            description: "This is a test",
            primary_subaccount_id: primary_subaccount.id,
            mivp_percent: 50,
          }
        )
      end

      let(:primary_subaccount) { create(:setup_account, expires_at: (Time.zone.now + 2.months).change(usec: 0)) }

      it "is a split account" do
        expect(account).to be_a UmassCorum::VoucherSplitAccount
      end

      it "sets splits" do
        expect(splits.size).to be(2)
      end

      it "sets expired_at to earliest expiring subaccount" do
        # The default expiration for the VoucherAccount is 25 years in the future
        expect(account.expires_at).to eq(primary_subaccount.expires_at)
      end

      it "only creates one VoucherAccount when run multiple times" do
        builder.build
        travel_to_and_return(1.week.from_now) { builder.build }
        expect(UmassCorum::VoucherAccount.all.size).to eq(1)
      end
    end

    describe "with a blank subaccount" do
      let(:params) do
        ActionController::Parameters.new(
          voucher_split_account: {
            primary_subaccount_id: "",
          }
        )
      end

      it "has two default subaccounts" do
        expect(splits.size).to eq(2)
      end
    end

    describe "with no subaccounts" do
      let(:params) { {} }

      it "has two default subaccounts" do
        expect(splits.size).to eq(2)
      end

      it "sets them to 100% and 0%" do
        expect(splits.first.percent).to eq(100)
        expect(splits.second.percent).to eq(0)
      end

      it "sets the last one, and only the last one to apply_remainder" do
        expect(splits.last).to be_apply_remainder
        expect(splits.first).not_to be_apply_remainder
      end
    end
  end
end
