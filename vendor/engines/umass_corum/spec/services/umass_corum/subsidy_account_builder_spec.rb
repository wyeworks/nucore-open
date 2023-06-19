# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SubsidyAccountBuilder do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build" do
    let(:account) { builder.build }
    let!(:speed_type_account) { create(:speed_type_account, :with_account_owner) }

    let(:options) do
      {
        account_type: "UmassCorum::SubsidyAccount",
        facility: build_stubbed(:facility),
        owner_user: create(:user),
        current_user: create(:user),
        params: params,
      }
    end

    describe "happy path" do
      let(:params) do
        ActionController::Parameters.new(
          subsidy_account: {
            account_number: speed_type_account.account_number,
            description: "This is a test",
          }
        )
      end

      it "builds a valid SubsidyAccount" do
        expect(account).to be_valid
      end

      it "has a funding source" do
        expect(account.funding_source).to be_a UmassCorum::SpeedTypeAccount
      end
    end
  end
end
