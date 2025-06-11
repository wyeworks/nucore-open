require "rails_helper"

RSpec.describe "Managing accounts" do
  let(:facility) { create(:facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:owner) { create(:user) }

  before { login_as director }

  describe "creation" do
    # This should be done in each school's engine because it's complicated to abstract
    # the different components as well as any prerequisites.
  end

  describe "editing" do
    let(:account_factory) { Account.config.account_types.first.demodulize.underscore }
    let!(:account) { create(account_factory, :with_account_owner, owner:) }

    it "can edit a payment source's description" do
      visit facility_accounts_path(facility)
      fill_in "search_term", with: account.account_number
      click_on "Search"
      click_on account.to_s
      click_on "Edit"
      fill_in "Description", with: "New description"
      click_on "Save"
      expect(page).to have_content("Description\nNew description")
    end
  end

  describe "editing purchase order accounts" do
    let!(:account) { create(:purchase_order_account, :with_account_owner, owner:, facility:) }

    context "monetary_cap field visibility" do
      before do
        visit facility_accounts_path(facility)
        fill_in "search_term", with: owner.first_name
        click_on "Search"
        click_on account.to_s
        click_on "Edit"
      end

      context "when feature flag is enabled", feature_setting: { purchase_order_monetary_cap: true } do
        it "shows the monetary cap field", :aggregate_failures do
          expect(page).to have_field("Monetary Cap")
          expect(page).to have_content("Optional monetary cap for this purchase order account")
        end

        it "can set and save monetary cap value" do
          fill_in "Monetary Cap", with: "1500.75"
          click_on "Save"

          expect(page).to have_content("The payment source was successfully updated")
          account.reload
          expect(account.monetary_cap).to eq(1500.75)
        end
      end

      context "when feature flag is disabled", feature_setting: { purchase_order_monetary_cap: false } do
        it "does not show the monetary cap field" do
          expect(page).not_to have_field("Monetary Cap")
          expect(page).not_to have_content("Optional monetary cap for this purchase order account")
        end
      end
    end
  end

  describe "changing a user's role" do
    let(:account_factory) { Account.config.account_types.first.demodulize.underscore }
    let!(:account) { create(account_factory, :with_account_owner, owner:) }

    context "from anything to owner" do
      let(:other_user) { create(:user) }
      let!(:user_role) do
        create(:account_user, account:, user: other_user, user_role: AccountUser::ACCOUNT_PURCHASER)
      end

      it "fails gracefully" do
        visit facility_accounts_path(facility)
        fill_in "search_term", with: account.account_number
        click_on "Search"
        click_on account.to_s
        click_on "Members"
        click_on "Add Access"
        fill_in "search_term", with: other_user.first_name
        click_on "Search"
        click_on other_user.last_first_name
        select "Owner", from: "Role"
        click_on "Create"
        expect(page).to have_content("#{other_user.full_name} is already a member. Please remove #{other_user.full_name} before adding them as the new Owner.")
      end
    end
  end

  describe "editing credit cards" do
    let!(:account) { create(:credit_card_account, :with_account_owner, owner:, facility:) }

    it "can edit a credit_cards expiration date", :aggregate_failures do
      visit facility_accounts_path(facility)
      fill_in "search_term", with: account.account_number
      click_on "Search"
      click_on account.to_s
      click_on "Edit"
      expect(page).to have_content("Expiration month")
      expect(page).to have_content("Expiration year")
      select "5", from: "Expiration month"
      select "#{Time.zone.today.year + 5}", from: "Expiration year"
      click_on "Save"
      expect(page).to have_content("Expiration\n05/31/#{Time.zone.today.year + 5}")
    end
  end

  describe(
    "hide far future expiration dates",
  ) do
    before do
      visit facility_accounts_path(facility)
      fill_in "search_term", with: account.account_number
      click_on "Search"
    end

    context "when expiration is less than 75 years from now" do
      let(:account) do
        create(
          :credit_card_account,
          :with_account_owner,
          owner:,
          facility:,
          expires_at: 75.years.from_now - 1.day
        )
      end

      it(
        "shows expiration date when ff is off",
        feature_setting: { hide_account_far_future_expiration: false },
      ) do
        within("table") do
          expect(page).to have_content(account.human_date(account.expires_at))
        end
      end

      it(
        "shows expiration date when ff is on",
        feature_setting: { hide_account_far_future_expiration: true },
      ) do
        within("table") do
          expect(page).to have_content(account.human_date(account.expires_at))
        end
      end
    end

    context "when expiration is more than 75 years from now" do
      let(:account) do
        create(
          :credit_card_account,
          :with_account_owner,
          owner:,
          facility:,
          expires_at: 75.years.from_now + 1.day
        )
      end

      it(
        "does not show expiration date when ff is on",
        feature_setting: { hide_account_far_future_expiration: true },
      ) do
        within("table") do
          expect(page).not_to have_content(account.human_date(account.expires_at))
        end
      end

      it(
        "shows expiration date when ff is off",
        feature_setting: { hide_account_far_future_expiration: false },
      ) do
        within("table") do
          expect(page).to have_content(account.human_date(account.expires_at))
        end
      end
    end
  end
end
