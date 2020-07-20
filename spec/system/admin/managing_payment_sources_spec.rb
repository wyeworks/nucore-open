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
end
