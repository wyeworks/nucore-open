# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityOrdersController do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price, facility: facility) }

  let(:account) { create(:nufs_account, :with_account_owner, owner: facility_director) }
  let!(:in_progress_occupancy) { create(:occupancy, :active, :with_order_detail, secure_room: secure_room, user: facility_director, account: account) }
  let!(:problem_occupancy) { create(:occupancy, :problem_with_order_detail, secure_room: secure_room, user: facility_director, account: account) }

  let(:facility_director) { create(:user, :facility_director, facility: facility) }

  before { sign_in facility_director }

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
