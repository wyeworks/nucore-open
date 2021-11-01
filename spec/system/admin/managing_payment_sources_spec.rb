require "rails_helper"

RSpec.describe "Managing accounts" do
  let(:facility) { create(:facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:owner) { create(:user) }

  before { login_as director }

  describe "creation" do
    # This should be done in each school's engine because it's complicated to abstract
    # the different components as well as any prerequisites.
  end

  describe "editing" do
    let(:account_factory) { Account.config.account_types.first.demodulize.underscore }
    let!(:account) { create(account_factory, :with_account_owner, owner: owner) }

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

  describe "changing a user's role" do
    let(:account_factory) { Account.config.account_types.first.demodulize.underscore }
    let!(:account) { create(account_factory, :with_account_owner, owner: owner) }

    context "from anything to owner" do
      let(:other_user) { create(:user) }
      let!(:user_role) do
        create(:account_user, account: account, user: other_user, user_role: AccountUser::ACCOUNT_PURCHASER)
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
    let!(:account) { FactoryBot.create(:credit_card_account, :with_account_owner, owner: owner, facility: facility) }

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
end
