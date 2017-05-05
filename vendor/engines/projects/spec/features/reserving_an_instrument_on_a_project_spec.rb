require "rails_helper"

RSpec.describe "Reserving an instrument on a project" do
  let!(:instrument) { FactoryGirl.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility_admin) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }
  let!(:account_price_group_member) do
    FactoryGirl.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let!(:project) { FactoryGirl.create(:project, facility: facility) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.full_name
    click_button "Search"
    click_link "Order For"
  end

  describe "and you create a reservation" do
    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      select project.name, from: "Project"
      click_button "Create"
    end

    it "returns to My Reservations" do
      expect(page).to have_content "My Reservations"
      expect(OrderDetail.last.project).to eq(project)
    end
  end
end
