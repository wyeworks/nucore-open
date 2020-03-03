# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reserving an instrument on a project" do
  let!(:instrument) { FactoryBot.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryBot.create(:user) }
  let(:facility_admin) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let!(:project) { FactoryBot.create(:project, facility: facility) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.email
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

    it "takes you to the receipt and has the project set" do
      expect(page).to have_content "Order Receipt"
      expect(OrderDetail.last.project).to eq(project)
    end
  end
end
