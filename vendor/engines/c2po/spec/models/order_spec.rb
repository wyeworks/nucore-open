# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  let(:facility) { @facility }

  before(:each) do
    @facility = FactoryBot.create(:setup_facility)
    @price_group = FactoryBot.create(:price_group, facility:)
    @order_status = FactoryBot.create(:order_status)
    @service = FactoryBot.create(:service, facility:, initial_order_status: @order_status)
    @service_pp = FactoryBot.create(:service_price_policy, product: @service, price_group: @price_group)
    @user = FactoryBot.create(:user)
    @pg_member = FactoryBot.create(:user_price_group_member, user: @user, price_group: @price_group)
    @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @order = @user.orders.create(FactoryBot.attributes_for(:order, created_by: @user.id, account: @account, facility: @facility))
  end

  it "should not allow validate if the account type is not allowed by the facility" do
    # facility does not accept credit card accounts
    @facility.accepts_cc = false
    @facility.save
    # create credit card account and link to order
    @cc_account = FactoryBot.create(:credit_card_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @order = FactoryBot.create(:order, user: @user, created_by: @user.id, account: @cc_account, facility: @facility)
    @order.order_details.create(product_id: @service.id, quantity: 1)
    # should not be allowed to purchase with a credit card account
    expect(@order.validate_order!).to be false
  end
end
