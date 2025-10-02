# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing mode workflows" do
  let(:facility) { create(:setup_facility, accepts_po:) }
  let(:accepts_po) { true }
  let(:billing_mode) { "Default" }
  let(:item) { create(:setup_item, facility:, billing_mode:) }
  let(:account) { create(:purchase_order_account, :with_account_owner, facility:) }
  let(:order) { create(:setup_order, product: item, account:) }
  let(:order_detail) { order.order_details.first }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:user) { order.account.owner.user }
  let(:logged_in_user) { nil }

  before do
    create(:account_price_group_member, account:, price_group: PriceGroup.base)

    login_as logged_in_user
  end

  describe "'Skip Review' billing mode" do
    let(:billing_mode) { "Skip Review" }

    context "with a valid account" do
      let(:logged_in_user) { director }

      it "automatically moves an order detail from complete to reconciled", :js do
        order._validate_order!
        order.purchase!
        visit manage_facility_order_order_detail_path(facility, order, order_detail)

        select "Complete", from: "Order Status"

        click_button "Save"

        expect(page).to have_content("The order was successfully updated")

        visit facility_transactions_path(facility)

        expect(page).to have_selector("tr td.nowrap", text: "Reconciled")
      end
    end

    context "with an invalid account" do
      let(:accepts_po) { false }
      let(:logged_in_user) { user }

      it "does not allow the product to be ordered" do
        visit facility_item_path(facility, item)
        expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this item")
      end
    end
  end

  describe "'Nonbillable' billing mode" do
    let(:billing_mode) { "Nonbillable" }
    let(:logged_in_user) { director }

    it "automatically moves an order detail from complete to reconciled", :js do
      order._validate_order!
      order.purchase!
      visit manage_facility_order_order_detail_path(facility, order, order_detail)

      select "Complete", from: "Order Status"

      click_button "Save"

      expect(page).to have_content("The order was successfully updated")

      visit facility_transactions_path(facility)

      expect(page).to have_selector("tr td.nowrap", text: "Reconciled")
    end
  end
end
