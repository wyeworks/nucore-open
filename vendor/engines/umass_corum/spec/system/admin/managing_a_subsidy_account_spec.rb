# frozen_string_literal: true

RSpec.describe "Managing a subsidy account" do
  let(:facility) { FactoryBot.create(:facility) }
  let!(:user) { create(:user) }
  let(:facility_admin) { create(:user, :facility_administrator, facility:) }
  let(:administrator) { create(:user, :administrator) }
  let!(:funding_source) do
    create(
      :speed_type_account,
      :with_account_owner,
      :with_api_speed_type,
      account_number: 173_276,
      description: "Funding source"
    )
  end

  describe "creating a subsidy account" do
    context "global admin" do
      before do
        login_as administrator
        visit new_account_user_search_facility_accounts_path(facility)
        fill_in :search_term, with: user.last_name
        click_button "Search"
        click_link user.last_name
        click_link "Subsidy Account"
      end

      it "can create a subsidy account" do
        fill_in "Description", with: "Test subsidy"
        select funding_source.to_s, from: "Funding Source"
        click_button "Create"
        expect(page).to have_content "Account was successfully created."
      end
    end

    context "facility admin" do
      before do
        login_as facility_admin
        visit new_account_user_search_facility_accounts_path(facility)
        fill_in :search_term, with: user.last_name
        click_button "Search"
        click_link user.last_name
      end

      it "cannot create a subsidy account" do
        expect(page).to_not have_content "Subsidy Account"
      end
    end
  end
end
