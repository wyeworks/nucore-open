# frozen_string_literal: true

RSpec.describe "Subsidy account billing" do
  let(:product) { create(:setup_item) }
  let(:facility) { product.facility }
  let(:subsidy_account) { create(:subsidy_account, :with_account_owner) }
  let(:order) { create(:setup_order, :purchased, account: subsidy_account, product:) }
  let(:administrator) { create(:user, :administrator) }

  before do
    order.order_details.each(&:to_complete!)
    login_as administrator
  end

  it "is automatically disputed" do
    visit facility_notifications_path(facility)
    check "order_detail_ids_"
    click_button "Send Notifications"
    click_on "Disputed Orders"
    expect(page).to have_content order.order_details.first.account.description
  end

end
