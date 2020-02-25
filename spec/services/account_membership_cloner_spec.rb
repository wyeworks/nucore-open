require "rails_helper"

RSpec.describe AccountMembershipCloner, type: :service do
  let(:facility) { create(:facility) }
  let(:acting_user) { create(:user, :administrator) }
  let(:original_user) { create(:user) }
  let(:new_user) { create(:user) }
  let!(:owned_account) { create(:account, :with_account_owner, owner: original_user) }
  let(:business_admin_account) { create(:account, :with_account_owner) }
  let(:purchaser_account) { create(:account, :with_account_owner) }
  let(:purchaser_account_to_not_clone) { create(:account, :with_account_owner) }

  let(:cloner) {
    described_class.new(
      account_users_to_clone: account_users_to_clone,
      clone_to_user: new_user,
      acting_user: acting_user,
    )
  }

  before do
    create(:account_user, :business_administrator, user: original_user, account: business_admin_account)
    create(:account_user, :purchaser, user: original_user, account: purchaser_account)
    create(:account_user, :purchaser, user: new_user, account: purchaser_account_to_not_clone)
  end

  describe "when #perform is called" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, account: business_admin_account) }

    it "clones the AccountUser objects for one user to a new one" do
      expect { cloner.perform }.to change(AccountUser, :count).by(1)
    end

    it "saves the cloned AccountUser with the appropriate attributes" do
      account_users = cloner.perform

      expect(account_users.first).to have_attributes(
        user_id: new_user.id,
        account_id: business_admin_account.id,
        user_role: AccountUser::ACCOUNT_ADMINISTRATOR,
        created_by_user: acting_user,
        deleted_at: nil,
      )
    end

    it "generates a LogEvent" do
      expect { cloner.perform }.to change(LogEvent, :count).by(1)
    end
  end

  describe "when invoked to clone an owned account" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, user_role: "owner") }

    it "assigns the cloned user the accepted alternate role" do
      account_users = cloner.perform

      expect(account_users.first.user_role).to eq(AccountMembershipCloner::ALT_FOR_PROTECTED_ROLE)
    end
  end

  describe "when attempting to clone an AccountUser where the new user already has an association" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, account: business_admin_account) }

    before do
      create(:account_user, :business_administrator, user: new_user, account: business_admin_account)
    end

    it "does not create a new AccountUser" do
      expect { cloner.perform }.to_not change(AccountUser, :count)
    end
  end

end
