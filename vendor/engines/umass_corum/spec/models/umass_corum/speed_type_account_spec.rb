# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SpeedTypeAccount do
  subject(:account) { build(:speed_type_account, :with_account_owner) }
  let(:account_number) { account.account_number }

  it { is_expected.to validate_uniqueness_of(:account_number).case_insensitive }

  # The invalid ones are based on real examples that got onto prod before we put
  # the format validations in place.
  describe "account_number format validations" do
    it "is valid for a reasonable chart string" do
      account.account_number = "123456"
      expect(account).to be_valid
    end

    it "is invalid if it is blank" do
      account.account_number = "...."
      expect(account).to be_invalid
      expect(account.errors).to be_added(:account_number, :invalid)
    end

    it "is invalid if it is not the right length" do
      account.account_number = "123"
      expect(account).to be_invalid
      expect(account.errors).to be_added(:account_number, :invalid)
    end

    it "is invalid if there is a leter in it" do
      account.account_number = "A23456"
      expect(account).to be_invalid
      expect(account.errors).to be_added(:account_number, :invalid)
    end
  end

  describe "#account_number_to_s" do
    it { expect(subject.account_number_to_s).to eq(account_number) }
  end
end
