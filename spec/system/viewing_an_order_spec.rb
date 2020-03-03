# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewing an order" do
  let(:facility) { product.facility }
  let(:product) { create(:setup_item, :with_facility_account) }
  let(:order) { create(:purchased_order, product: product) }
  let!(:order_detail) { order.order_details.first }
  let(:user) { create(:user, :staff, facility: facility) }

  before do
    login_as user
  end

  describe "badge displays" do
    describe "a complete order missing a price policy" do
      before do
        order_detail.complete!
        order_detail.update(price_policy: nil)
      end

      it "displays a badge" do
        visit facility_order_path(facility, order)
        within("#order-management") do
          expect(page).to have_content "Missing Price Policy"
        end
      end
    end

    describe "a canceled order missing a price policy" do
      before do
        order_detail.to_canceled!
        order_detail.update(price_policy: nil)
      end

      it "displays no stinkin' badges" do
        visit facility_order_path(facility, order)
        within("#order-management") do
          expect(page).not_to have_content "Missing Price Policy"
        end
      end
    end
  end
end
