# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resolving a disputed order" do
  let(:item) { create(:setup_item) }
  let(:facility) { item.facility }
  let(:owner) { create(:user) }
  let(:administrator) { create(:user, :administrator) }
  let(:facility_admin) { create(:user, :facility_director, facility:) }
  let(:account) { create(:account, :with_account_owner, owner:) }
  let(:order) { create(:complete_order, product: item, account:) }
  let(:logged_in_user) { nil }

  let!(:order_detail) do
    create(
      :order_detail,
      :disputed,
      product: item,
      order: order,
      dispute_by: owner,
      dispute_reason: "Testing, testing",
      fulfilled_at: Date.today,
      account: account
    )
  end

  before do
    allow_any_instance_of(OrderDetailNoticePresenter).to receive(:global_admin_must_resolve?).and_return(true)
    login_as logged_in_user
    visit facility_disputed_orders_path facility
    find_link(
      href: manage_facility_order_order_detail_path(facility, order, order_detail)
    ).click
  end

  context "logged in as global administrator" do
    let(:logged_in_user) { administrator }

    it "allows global admins to resolve a disputed order" do
      click_on "Save"
      expect(page).to have_content "The order was successfully updated."
    end
  end

  context "logged in as user who is not a global administrator" do
    let(:logged_in_user) { facility_admin }

    it "does not allow non-global admins to resolve a disputed order" do
      expect(page).to have_content I18n.t("order_details.notices.global_admin_must_resolve.alert")
    end
  end
end
