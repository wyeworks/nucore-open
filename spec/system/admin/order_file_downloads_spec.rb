# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order file downloads", feature_setting: { granular_permissions: true } do
  let(:product) { create(:setup_service) }
  let(:facility) { product.facility }
  let(:order) { create(:purchased_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:user) { create(:user) }
  let!(:file) { create(:stored_file, :results, order_detail:, file_type: "template_result") }
  let(:download_path) { template_results_facility_order_order_detail_path(facility, order, order_detail, file) }

  before do
    create(:facility_user_permission, user:, facility:, read_access: true)
    login_as user
    visit facility_order_path(facility, order)
  end

  it "downloads an order file with only read_access" do
    find_link(href: download_path).click

    expect(page.status_code).to eq(200)
    expect(page.body).to eq("c,s,v")
  end
end
