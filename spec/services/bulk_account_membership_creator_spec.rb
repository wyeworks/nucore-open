# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkAccountMembershipCreator, type: :service do
  let(:acting_user) { create(:user, :administrator) }
  let(:user) { create(:user) }
  let(:first_account) { create(:account, :with_account_owner) }
  let(:second_account) { create(:account, :with_account_owner) }
  let(:accounts) { Account.where(id: [first_account.id, second_account.id]) }
  let(:creator) { described_class.new(accounts:, user:, acting_user:) }

  describe "#perform" do
    it "adds the user as business administrator to every account" do
      expect(creator.perform).to be(true)

      expect(AccountUser.active.where(user:)).to contain_exactly(
        have_attributes(account_id: first_account.id, user_role: AccountUser::ACCOUNT_ADMINISTRATOR, created_by: acting_user.id),
        have_attributes(account_id: second_account.id, user_role: AccountUser::ACCOUNT_ADMINISTRATOR, created_by: acting_user.id),
      )
      expect(creator.account_users.size).to eq(2)
    end

    it "logs a create event for each new membership" do
      expect { creator.perform }.to change(LogEvent.where(event_type: "create", user: acting_user), :count).by(2)
    end

    context "when the user is already a member of one of the accounts" do
      before { create(:account_user, :purchaser, user:, account: second_account) }

      it "does not create any membership" do
        expect(creator.perform).to be(false)

        expect(AccountUser.active.where(user:).pluck(:account_id, :user_role)).to eq([[second_account.id, AccountUser::ACCOUNT_PURCHASER]])
        expect(creator.error.record.account).to eq(second_account)
      end

      it "does not log any event" do
        expect { creator.perform }.not_to change(LogEvent, :count)
      end
    end
  end
end
