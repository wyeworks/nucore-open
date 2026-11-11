# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bulk account memberships" do
  let(:admin) { create(:user, :administrator) }
  let(:user) { create(:user) }
  let(:account) { create(:account, :with_account_owner) }
  let(:facility) { create(:facility) }

  context "when the feature is enabled", feature_setting: { "accounts.bulk_add_business_administrator" => true } do
    context "as a global admin" do
      before { login_as admin }

      it "adds the user as business administrator" do
        expect do
          post facility_user_bulk_account_memberships_path("all", user), params: { account_ids: [account.id] }
        end.to change { account.account_users.active.business_administrators.where(user:).count }.from(0).to(1)

        expect(response).to redirect_to(facility_user_accounts_path("all", user))
      end

      it "redirects back with an error when no payment source is selected" do
        expect do
          post facility_user_bulk_account_memberships_path("all", user)
        end.not_to change(AccountUser, :count)

        expect(response).to redirect_to(facility_user_bulk_account_memberships_path("all", user))
        expect(flash[:error]).to eq("Please select at least one payment source.")
      end

      it "redirects back with an error when the user is already a member" do
        create(:account_user, :purchaser, user:, account:)

        post facility_user_bulk_account_memberships_path("all", user), params: { account_ids: [account.id] }

        expect(response).to redirect_to(facility_user_bulk_account_memberships_path("all", user))
        expect(flash[:error]).to include(account.to_s)
        expect(account.account_users.active.find_by(user:).user_role).to eq(AccountUser::ACCOUNT_PURCHASER)
      end

      it "rejects a search term that is too short" do
        get facility_user_bulk_account_memberships_path("all", user), params: { search_term: "ab" }

        expect(response.body).to include("Search terms must be 3 or more characters.")
      end

      it "is not available in a single facility" do
        get facility_user_bulk_account_memberships_path(facility, user)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a facility director" do
      let(:director) { create(:user, :facility_director, facility:) }

      before { login_as director }

      it "is forbidden" do
        post facility_user_bulk_account_memberships_path("all", user), params: { account_ids: [account.id] }

        expect(response).to have_http_status(:forbidden)
        expect(account.account_users.where(user:)).to be_empty
      end
    end
  end

  context "when the feature is disabled", feature_setting: { "accounts.bulk_add_business_administrator" => false } do
    before { login_as admin }

    it "responds not found" do
      post facility_user_bulk_account_memberships_path("all", user), params: { account_ids: [account.id] }

      expect(response).to have_http_status(:not_found)
      expect(account.account_users.where(user:)).to be_empty
    end
  end
end
