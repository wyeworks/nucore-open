# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccountOrdersController do
  render_views

  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_item, facility: facility) }
  let(:account) { create(:account, :with_account_owner) }
  let(:admin) { create(:user, :administrator) }
  let!(:purchased_order) { create(:purchased_order, product: product, account: account) }

  it "renders" do
    sign_in admin
    get :index, params: { facility_id: facility.url_name, account_id: account.id }
    expect(response.status).to eq(200)
  end
end
