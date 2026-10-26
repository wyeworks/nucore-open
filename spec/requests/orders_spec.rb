# frozen_string_literal: true

require "rails_helper"

RSpec.describe "orders" do
  describe "adding to cart when the cart has no account" do
    let(:user) { create(:user) }
    let(:product) { create(:setup_item) }
    let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
    let!(:price_policy) do
      create(:item_price_policy, price_group: PriceGroup.base, product:, unit_cost: 33.25)
    end
    let!(:account_price_group_member) do
      create(:account_price_group_member, account:, price_group: price_policy.price_group)
    end
    let(:order) { user.cart(user) }

    around do |example|
      app_config = Rails.application.env_config
      previous_serializer = app_config["action_dispatch.cookies_serializer"]
      app_config["action_dispatch.cookies_serializer"] = :json
      example.run
    ensure
      app_config["action_dispatch.cookies_serializer"] = previous_serializer
    end

    before { login_as user }

    it "keeps the items in a JSON session while the account is chosen", :aggregate_failures do
      put add_order_path(order), params: { order: { order_details: [{ product_id: product.id, quantity: 2 }] } }

      expect(response).to redirect_to(choose_account_order_path(order))
      expect(session[:add_to_cart]).to eq([{ "product_id" => product.id, "quantity" => 2 }])

      get choose_account_order_path(order)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.to_s)

      post choose_account_order_path(order), params: { account_id: account.id }

      expect(response).to redirect_to(add_order_path(order))

      get add_order_path(order)

      expect(response).to redirect_to(order_path(order))
      expect(session[:add_to_cart]).to be_nil
      expect(order.reload.account).to eq(account)
      expect(order.order_details.map { |od| [od.product, od.quantity] }).to eq([[product, 2]])
    end
  end
end
