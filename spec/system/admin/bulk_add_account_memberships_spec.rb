# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bulk adding a business administrator to payment sources" do
  let(:facility) { create(:facility) }
  let(:user) { create(:user) }
  let(:principal_investigator) { create(:user, last_name: "Investigatorson") }
  let!(:first_account) { create(:account, :with_account_owner, owner: principal_investigator) }
  let!(:second_account) { create(:account, :with_account_owner, owner: principal_investigator) }
  let!(:existing_membership_account) { create(:account, :with_account_owner, owner: principal_investigator) }
  let!(:other_account) { create(:account, :with_account_owner) }

  before do
    allow(Account.config).to receive(:global_account_types).and_return(["Account"])
    create(:account_user, :purchaser, user:, account: existing_membership_account)
  end

  context "when the feature is enabled", feature_setting: { "accounts.bulk_add_business_administrator" => true } do
    describe "as a global admin" do
      let(:admin) { create(:user, :administrator) }

      before { login_as admin }

      it "can't see the button in a single facility" do
        visit facility_user_accounts_path(facility, user)

        expect(page).not_to have_link("Bulk Add Business Administrator")
      end

      it "adds the user as business administrator to the selected payment sources" do
        visit facility_user_accounts_path("all", user)
        click_link "Bulk Add Business Administrator"

        fill_in "search_term", with: "Investigatorson"
        click_button "Search"

        expect(page).to have_content(first_account.to_s)
        expect(page).to have_content(second_account.to_s)
        expect(page).to have_content(existing_membership_account.to_s)
        expect(page).not_to have_content(other_account.to_s)
        expect(page).to have_field("accountId#{existing_membership_account.id}", disabled: true)

        check "accountId#{first_account.id}"
        check "accountId#{second_account.id}"
        click_button "Add as Business Administrator"

        expect(page).to have_content("#{user.full_name} was added as Business Administrator to 2 payment sources.")
        expect(user.account_users.active.business_administrators.pluck(:account_id)).to contain_exactly(first_account.id, second_account.id)
        expect(existing_membership_account.account_users.active.find_by(user:).user_role).to eq(AccountUser::ACCOUNT_PURCHASER)
      end

      it "shows a message when nothing matches" do
        visit facility_user_bulk_account_memberships_path("all", user, search_term: "no-such-account")

        expect(page).to have_content("No payment sources found")
      end
    end

    describe "as an account manager" do
      let(:account_manager) { create(:user, :account_manager) }

      before { login_as account_manager }

      it "can't access" do
        visit facility_user_accounts_path("all", user)
        expect(page).not_to have_link("Bulk Add Business Administrator")

        visit facility_user_bulk_account_memberships_path("all", user)
        expect(page).to have_http_status(:forbidden)
      end
    end
  end

  context "when the feature is disabled", feature_setting: { "accounts.bulk_add_business_administrator" => false } do
    let(:admin) { create(:user, :administrator) }

    before { login_as admin }

    it "does not show the button" do
      visit facility_user_accounts_path("all", user)

      expect(page).to have_link("Clone Payment Source Memberships")
      expect(page).not_to have_link("Bulk Add Business Administrator")
    end
  end
end
