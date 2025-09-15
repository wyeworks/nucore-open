# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetail do
  describe "#price_groups with user_based_price_groups_exclude_purchaser feature" do
    let(:product) { create(:setup_item) }
    let(:facility) { product.facility }
    let(:purchaser) { create(:user) }
    let(:account_owner) { create(:user) }
    let(:account) { create(:setup_account, owner_user: account_owner, facility:) }
    let(:order) { create(:order, user: purchaser, facility:, account:, created_by: purchaser.id) }
    let(:order_detail) do
      create(:order_detail, order:, product:, account:)
    end

    let(:purchaser_price_group) { create(:price_group, name: "Purchaser Group", facility:) }
    let(:owner_price_group) { create(:price_group, name: "Owner Group", facility:) }

    before do
      purchaser.price_groups << purchaser_price_group
      account_owner.price_groups << owner_price_group
      account.account_users.create!(user: purchaser, user_role: AccountUser::ACCOUNT_PURCHASER, created_by: 1)
    end

    context "when feature is disabled", feature_setting: { user_based_price_groups_exclude_purchaser: false } do
      it "uses purchaser's price groups plus account's price groups" do
        expect(order_detail.price_groups).to include(purchaser_price_group)
        expect(order_detail.price_groups).to include(owner_price_group)
      end
    end

    context "when feature is enabled", feature_setting: { user_based_price_groups_exclude_purchaser: true } do
      it "excludes purchaser's price groups, uses only account's price groups" do
        expect(order_detail.price_groups).to include(owner_price_group)
        expect(order_detail.price_groups).not_to include(purchaser_price_group)
      end

      it "returns empty array when no account present" do
        order_detail.account = nil
        expect(order_detail.price_groups).to eq([])
      end
    end
  end
end
