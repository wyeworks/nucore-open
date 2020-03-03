# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Placing an order with a project" do
  let!(:product) { FactoryBot.create(:setup_item) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { product.facility }
  let(:facility_admin) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
  let!(:price_policy) do
    FactoryBot.create(:item_price_policy,
                      price_group: PriceGroup.base, product: product,
                      unit_cost: 33.25)
  end
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let(:user) { FactoryBot.create(:user) }
  let!(:project) { FactoryBot.create(:project, facility: facility) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.email
    click_button "Search"
    click_link "Order For"
  end

  describe "adding an item to the cart" do
    def add_to_cart
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it "can place an order", :aggregate_failures do
      add_to_cart
      select project.name, from: "Project"
      click_button "Purchase"
      expect(OrderDetail.last.project).to eq(project)
    end
  end
end
