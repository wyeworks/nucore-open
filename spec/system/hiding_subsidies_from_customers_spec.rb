# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hiding subsidies from customers", feature_setting: { "pricing.hide_subsidy_from_customers" => true } do
  let!(:product) { create(:setup_item) }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { product.facility }
  let!(:price_policy) do
    create(:item_price_policy,
           price_group: PriceGroup.base,
           product:,
           unit_cost: 100,
           unit_subsidy: 20)
  end
  let!(:account_price_group_member) do
    create(:account_price_group_member, account:, price_group: price_policy.price_group)
  end
  let(:user) { create(:user) }

  # The setup_item factory adds its own policy for the facility's price group, which
  # the order factories enroll accounts in. Give it the same amounts so the totals
  # are the same whichever of the two policies ends up applying.
  before do
    product.price_policies.where.not(id: price_policy.id).update_all(unit_cost: 100, unit_subsidy: 20)
  end

  describe "as the customer" do
    before { login_as user }

    def add_to_cart
      visit facility_path(facility)
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it "shows only the total in the cart, on the receipt and on the order detail", :aggregate_failures do
      add_to_cart

      expect(page).to have_content("$80.00")
      expect(page).not_to have_content("$100.00")
      expect(page).not_to have_content("Adjustment")

      click_button "Purchase"

      expect(page).to have_content("Order Receipt")
      expect(page).to have_content("$80.00")
      expect(page).not_to have_content("$100.00")
      expect(page).not_to have_content("Adjustment")

      order_detail = OrderDetail.last
      visit order_order_detail_path(order_detail.order, order_detail)

      expect(page).to have_content("$80.00")
      expect(page).not_to have_content("$100.00")
      expect(page).not_to have_content("Adjustment")
    end
  end

  describe "as facility staff" do
    let!(:order) { create(:purchased_order, product:, account:) }
    let(:facility_admin) { create(:user, :facility_administrator, facility:) }

    before { login_as facility_admin }

    it "still shows the full breakdown on the facility order page", :aggregate_failures do
      visit facility_order_path(facility, order)

      expect(page).to have_content("Subsidy")
      expect(page).to have_content("$100.00")
      expect(page).to have_content("$80.00")
    end
  end
end
