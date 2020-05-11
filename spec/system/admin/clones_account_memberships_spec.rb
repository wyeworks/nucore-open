require "rails_helper"

RSpec.describe "Cloning account membership" do
  let(:facility) { create(:facility) }
  let(:original_user) { create(:user) }
  let(:new_user) { create(:user) }
  let!(:owned_account) { create(:account, :with_account_owner, owner: original_user) }
  let(:business_admin_account) { create(:account, :with_account_owner) }
  let(:purchaser_account) { create(:account, :with_account_owner) }
  let(:purchaser_account_to_not_clone) { create(:account, :with_account_owner) }

  before do
    allow(Account.config).to receive(:global_account_types).and_return(["Account"])

    create(:account_user, :business_administrator, user: original_user, account: business_admin_account)
    create(:account_user, :purchaser, user: original_user, account: purchaser_account)
    create(:account_user, :purchaser, user: new_user, account: purchaser_account_to_not_clone)
  end

  describe "as a global admin" do
    let(:admin) { create(:user, :administrator) }
    before { login_as admin }

    it "can't see the button in a single facility" do
      visit facility_user_accounts_path(facility, new_user)
      expect(page).not_to have_content "Clone"
    end

    it "can clone the account roles to the new user" do
      visit facility_user_accounts_path("all", new_user)

      click_link "Clone Payment Source Membership"
      fill_in "search_term", with: original_user.email
      click_button "Search"

      click_link "Clone Payment Source Memberships"

      find(:css, "#accountId#{owned_account.id}").set(true)
      find(:css, "#accountId#{business_admin_account.id}").set(true)
      find(:css, "#accountId#{purchaser_account.id}").set(true)

      expect(page).to have_content(owned_account.to_s)
      expect(page).to have_content(business_admin_account.to_s)
      expect(page).to have_content(purchaser_account.to_s)
      expect(page).not_to have_content(purchaser_account_to_not_clone.to_s)

      click_button "Clone"

      expect(page).to have_content("Successfully cloned")
    end
  end

  describe "as a account manager" do
    let(:account_manager) { create(:user, :account_manager) }
    before { login_as account_manager }

    it "can't access" do
      visit facility_user_accounts_path("all", new_user)
      expect(page).not_to have_content("Clone")

      visit facility_user_clone_account_memberships_path("all", new_user)
      expect(page.status_code).to eq(403)
    end
  end
end
