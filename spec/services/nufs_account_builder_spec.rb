# frozen_string_literal: true

require "rails_helper"

RSpec.describe NufsAccountBuilder, type: :service do
  let(:builder) { described_class.new(options) }

  it "is an AccountBuilder" do
    expect(described_class).to be <= AccountBuilder
  end

  describe "#build override" do
    before { allow(AccountValidator::ValidatorFactory).to receive(:validator_class).and_return(AccountValidator::ValidatorDefault) }

    let(:options) do
      {
        account_type: "NufsAccount",
        facility: build_stubbed(:facility),
        owner_user: build_stubbed(:user),
        current_user: build_stubbed(:user),
        params: params,
      }
    end

    describe "without params (like FacilityAccounts#new)" do
      let(:params) { {} }

      it "has no errors, even load_components raises an error" do
        allow_any_instance_of(NufsAccount).to receive(:load_components).and_raise(AccountValidator::ValidatorError, "validation error")

        expect(builder.build.errors).to be_empty
      end
    end

    describe "with params" do
      let(:params) do
        ActionController::Parameters.new(
          nufs_account: {
            account_number: "1234",
            description: "foobar",
          },
        )
      end

      it "sets expired_at" do
        expect(builder.build.expires_at).to be_present
      end

      it "sets the account_number" do
        expect(builder.build.account_number).to eq("1234")
      end

      it "sets the description" do
        expect(builder.build.description).to eq("foobar")
      end

      it "still sets the expiration date on a validator error" do
        allow_any_instance_of(AccountValidator::ValidatorDefault).to receive(:latest_expiration).and_raise(AccountValidator::ValidatorError)
        expect(builder.build.expires_at).to be_present
      end
    end
  end
end
