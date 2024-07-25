# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilitiesController do
  describe "#transactions" do
    let(:facility) { FactoryBot.create(:setup_facility) }
    let(:product) { FactoryBot.create(:setup_item, facility: facility) }
    let(:project) { FactoryBot.create(:project, facility: facility) }
    let(:order) { FactoryBot.create(:purchased_order, product: product) }
    let(:order_detail) { order.order_details.first }
    let(:order2) { FactoryBot.create(:purchased_order, product: product) }
    let(:order_detail2) { order2.order_details.first }

    let(:admin) { FactoryBot.create(:user, :administrator) }

    before do
      order_detail.update(project: project)
      sign_in admin
    end

    it "returns both order details with no filter" do
      get :transactions, params: { facility_id: facility.url_name, search: { projects: [], date_range_field: "ordered_at" } }
      expect(assigns(:order_details)).to contain_all([order_detail, order_detail2])
    end

    it "returns only the order detail selected" do
      get :transactions, params: { facility_id: facility.url_name, search: { projects: [project.id], date_range_field: "ordered_at" } }
      expect(assigns(:order_details)).to eq([order_detail])
    end

    it "includes the projects in the search" do
      get :transactions, params: { facility_id: facility.url_name }
      expect(assigns(:search)[:projects]).to eq([project])
    end
  end
end
