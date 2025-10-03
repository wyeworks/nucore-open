# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityOrdersController do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price, facility:) }
  let(:account) { create(:nufs_account, :with_account_owner, owner: facility_director) }
  let(:facility_director) { create(:user, :facility_director, facility:) }

  before do
    create(:account_price_group_member, account:, price_group: PriceGroup.base)
    create(:occupancy, :active, :with_order_detail, secure_room:, user: facility_director, account:)
    create(:occupancy, :problem_with_order_detail, secure_room:, user: facility_director, account:)
    sign_in facility_director
  end

  describe "index" do
    before { get :index, params: { facility_id: facility } }

    it "does not include the occupancies" do
      expect(response).to be_successful
      expect(assigns(:order_details)).to eq([])
    end
  end

  describe "show_problems" do
    before { get :show_problems, params: { facility_id: facility } }

    it "does not include the occupancies" do
      expect(response).to have_http_status(:ok)
      expect(assigns(:order_details)).to eq([])
    end
  end
end
