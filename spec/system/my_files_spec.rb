# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visiting my files", feature_setting: { my_files: true, reload_routes: true } do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let!(:service) { FactoryBot.create(:setup_service, facility: facility) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:service_price_policy, price_group: PriceGroup.base, product: service) }
  let(:user) { FactoryBot.create(:user) }

  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  let!(:order) { FactoryBot.create(:purchased_order, product: service, account: account) }
  let(:order_detail) { order.order_details.first }
  let!(:file) { FactoryBot.create(:stored_file, :results, order_detail: order_detail, product: service) }

  before do
    login_as user
    visit root_path
    click_link("My Files", match: :first)
  end

  it "has my files" do
    expect(page).to have_link(order_detail.to_s)
  end

end
