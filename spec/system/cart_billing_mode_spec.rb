# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding products with different billing modes to cart" do
  let(:facility) { create(:setup_facility) }
  let(:billing_mode) { "Default" }
  let!(:nonbillable_item) { create(:setup_item, facility:, billing_mode: "Nonbillable") }
  let!(:default_item) { create(:setup_item, facility:, billing_mode: "Default") }
  let!(:account) { create(:purchase_order_account, :with_account_owner, facility:) }
  let!(:nonbillable_price_policy) { create(:item_price_policy, price_group: PriceGroup.globals.first, product: nonbillable_item) }
  let!(:default_price_policy) { create(:item_price_policy, price_group: PriceGroup.globals.first, product: default_item) }
  let(:user) { account.owner.user }

  before do
    login_as user
  end

  context "when a user has no account" do
    let(:user) do
      u = account.owner.user
      u.account_users.each { |au| au.destroy }
      u.save
      u.reload
    end

    it "allows a user without any accounts to add a nonbillable product to cart" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content(nonbillable_item.name)
    end

    it "does not allow a user without any accounts to add a default product to cart" do
      visit facility_item_path(facility, default_item)
      expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this item")
    end
  end

  context "when a nonbillable product is added first" do
    before do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
    end

    it "allows a user to add another nonbillable product" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content(nonbillable_item.name).twice
    end

    it "does not allow a user to add a default billing mode product" do
      visit facility_item_path(facility, default_item)
      click_on "Add to cart"
      expect(page).to have_content("#{default_item.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
    end
  end

  context "when a default product is added first" do
    before do
      visit facility_item_path(facility, default_item)
      click_on "Add to cart"
      choose account.description
      click_on "Continue"
    end

    it "allows a user to add another default product" do
      visit facility_item_path(facility, default_item)
      click_on "Add to cart"
      expect(page).to have_content(default_item.name).twice
    end

    it "does not allow a user to add another nonbillable product" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content("#{nonbillable_item.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
    end
  end
end
