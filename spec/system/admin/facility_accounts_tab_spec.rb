# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Accounts Tab" do
  let(:admin) { create(:user, :administrator) }
  let(:account_type1) { Account.config.journal_account_types.first.demodulize }
  let(:account_type2) { Account.config.statement_account_types.first.demodulize }
  let(:facility) { create(:setup_facility) }
  let(:active_account) do
    create(
      account_type1.underscore,
      :with_account_owner,
      expires_at: 1.day.from_now,
    )
  end
  let(:expired_account) do
    create(
      account_type2.underscore,
      :with_account_owner,
      expires_at: 1.day.ago,
    )
  end
  let(:suspended_account) do
    create(
      account_type1.underscore,
      :with_account_owner,
      suspended_at: 1.day.ago
    )
  end
  let(:product) { create(:setup_item, facility:) }

  before do
    [active_account, expired_account, suspended_account].each do |account|
      create(:purchased_order, product:, account:, ordered_at: 5.days.ago)
    end

    login_as admin
  end

  context "when the feature flag is on", feature_setting: { account_tabs: true } do

    before do
      visit facility_accounts_path(facility)
    end

    it "should hide the Hide Expired Accounts button" do
      expect(page).to have_no_button("Hide Expired Accounts")
    end

    it "should show both active and expired accounts by default" do
      expect(page).to have_content(active_account.to_s)
      expect(page).to have_content(expired_account.to_s)
      expect(page).to have_no_content(suspended_account.to_s)
    end

    context "when in the active tab" do
      it "should filter by account status" do
        select I18n.t("account.statuses.active"), from: I18n.t("facility_accounts.index.label.account_status")
        find('[data-test-id="account_search_button"]').click
        # Wait for the loader to not be found, which is when the search results are shown
        expect(page).to have_no_css('[data-test-id="account_search_button"]', text: "Please Wait...")
        expect(page).to have_content(active_account.to_s)
        expect(page).to have_no_content(expired_account.to_s)
        expect(page).to have_no_content(suspended_account.to_s)
      end

      it "should filter by account type" do
        select active_account.model_name.human, from: I18n.t("facility_accounts.index.label.account_type")
        find('[data-test-id="account_search_button"]').click
        # Wait for the loader to not be found, which is when the search results are shown
        expect(page).to have_no_css('[data-test-id="account_search_button"]', text: "Please Wait...")
        expect(page).to have_content(active_account.to_s)
        expect(page).to have_no_content(expired_account.to_s)
        expect(page).to have_no_content(suspended_account.to_s)
      end
    end

    context "when in the suspended tab" do
      it "should show suspended accounts" do
        click_link I18n.t("views.facility_accounts.accounts_tab_nav.suspended")
        expect(page).to have_no_content(active_account.to_s)
        expect(page).to have_no_content(expired_account.to_s)
        expect(page).to have_content(suspended_account.to_s)
      end

      it "should not have the filter by account status" do
        click_link I18n.t("views.facility_accounts.accounts_tab_nav.suspended")
        expect(page).to have_no_content(I18n.t("facility_accounts.index.label.account_status"))
      end
    end

  end

  context "when the feature flag is off", feature_setting: { account_tabs: false } do
    it "should not assign the account types" do
      visit facility_accounts_path(facility)
      expect(page).to have_no_select("Account Type")
    end

    it "should show the Hide Expired Accounts button" do
      visit facility_accounts_path(facility)
      expect(page).to have_content("Hide Expired Accounts")
    end
  end
end
