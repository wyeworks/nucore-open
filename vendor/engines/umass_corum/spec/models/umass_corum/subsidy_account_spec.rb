# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::SubsidyAccount do
  let(:subsidy_account) { create(:subsidy_account, :with_account_owner) }
  let(:funding_source) { subsidy_account.funding_source }

  describe "#auto_dispute_by" do
    it "should return the owner of the funding source" do
      expect(subsidy_account.auto_dispute_by).to eq funding_source.owner.user
    end
  end

  describe "#administrators" do
    # For SubsidyAccounts, the owner of the funding source should be sent
    # notificatons, along with the administrators of the account.
    # NotificationSender#notifications_hash uses `account#administrators` to
    # get the list of users to notify
    it "includes the funding source owner" do
      expect(subsidy_account.administrators).to include subsidy_account.funding_source_owner
    end
  end
end
