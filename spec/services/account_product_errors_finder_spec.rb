# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountProductErrorsFinder do
  subject(:errors) { described_class.new(accounts, products, user).errors }

  let(:user) { instance_double(User) }
  let(:product) { instance_double(Item) }
  let(:other_product) { instance_double(Item) }
  let(:account) { instance_double(Account, id: 1) }
  let(:other_account) { instance_double(Account, id: 2) }

  let(:accounts) { [account] }
  let(:products) { [product] }

  describe "with no accounts" do
    let(:accounts) { [] }

    it { is_expected.to eq({}) }
  end

  describe "with no products" do
    let(:products) { [] }

    it { is_expected.to eq({}) }
  end

  describe "when the account can purchase every product" do
    let(:products) { [product, other_product] }

    before { allow(account).to receive(:validate_against_product).and_return(nil) }

    it "leaves the account out of the hash rather than mapping it to nil" do
      expect(errors).to eq({})
      expect(errors).not_to have_key(account.id)
    end
  end

  describe "when the account cannot purchase one of the products" do
    let(:products) { [product, other_product] }

    before do
      allow(account).to receive(:validate_against_product).with(product, user).and_return(nil)
      allow(account).to receive(:validate_against_product).with(other_product, user).and_return("no good")
    end

    it { is_expected.to eq(account.id => "no good") }
  end

  describe "when the account cannot purchase more than one of the products" do
    let(:products) { [product, other_product] }

    before do
      allow(account).to receive(:validate_against_product).with(product, user).and_return("first failure")
      allow(account).to receive(:validate_against_product).with(other_product, user).and_return("second failure")
    end

    it "reports the first failure" do
      expect(errors[account.id]).to eq("first failure")
    end

    it "stops validating the account once it has failed" do
      errors

      expect(account).not_to have_received(:validate_against_product).with(other_product, user)
    end
  end

  describe "when one account fails" do
    let(:accounts) { [account, other_account] }

    before do
      allow(account).to receive(:validate_against_product).and_return("no good")
      allow(other_account).to receive(:validate_against_product).and_return(nil)
    end

    it "still validates the remaining accounts" do
      expect(errors).to eq(account.id => "no good")
      expect(other_account).to have_received(:validate_against_product).with(product, user)
    end
  end
end
