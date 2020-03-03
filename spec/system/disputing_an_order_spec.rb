# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Disputing an order" do
  let(:item) { create(:setup_item) }
  let(:owner) { create(:user) }
  let(:account) { create(:account, :with_account_owner, owner: owner) }
  let(:order) { create(:complete_order, product: item, account: account) }
  let(:order_detail) { order.order_details.first }

  before do
    order_detail.update(reviewed_at: 1.week.from_now)
  end

  it "can dispute an order" do
    login_as owner
    visit in_review_transactions_path

    click_link "Dispute"
    fill_in "Dispute Reason", with: "It's bad"
    click_button "Dispute"

    expect(page).to have_content("Your purchase has been disputed")
    expect(current_path).to eq(in_review_transactions_path)
  end

end
