# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccount do
  describe "#revenue_account" do
    it "is an integer" do
      is_expected.to validate_numericality_of(:revenue_account).only_integer
    end
  end

  describe "#account_number" do
    let(:existing) { create(:facility_account) }

    it "is unique per facility and revenue account" do
      duplicate = build(
        :facility_account,
        facility: existing.facility,
        revenue_account: existing.revenue_account,
        account_number: existing.account_number,
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:account_number]).to be_present
    end

    it "is unique per facility and revenue account in the database" do
      duplicate = build(
        :facility_account,
        facility: existing.facility,
        revenue_account: existing.revenue_account,
        account_number: existing.account_number,
      )

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same account number under a different revenue account" do
      other = build(
        :facility_account,
        facility: existing.facility,
        revenue_account: existing.revenue_account + 1,
        account_number: existing.account_number,
      )

      expect(other).to be_valid
    end
  end
end
