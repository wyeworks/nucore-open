# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentsDashboardController do
  let(:facility) { create(:facility) }

  describe "dashboard" do
    def do_request
      get :dashboard, params: { facility_id: facility.url_name }
    end

    it "requires login" do
      do_request
      expect(response).to redirect_to(new_user_session_url)
    end

    it "allows facility staff" do
      sign_in create(:user, :staff, facility: facility)
      do_request
      expect(response).to be_successful
    end

    it "blocks staff from another facility" do
      sign_in create(:user, :staff, facility: create(:facility))
      do_request
      expect(response).to be_forbidden
    end
  end

  describe "public dashboard" do
    it "does not allow access if it is not turned on" do
      get :public_dashboard, params: { facility_id: facility.url_name, token: "" }
      expect(response).to be_not_found
    end

    it "allows access with the token" do
      facility.update!(dashboard_enabled: true)
      get :public_dashboard, params: { facility_id: facility.url_name, token: facility.dashboard_token }
      expect(response).to be_successful
    end

    it "does not allow access if the token is wrong" do
      facility.update!(dashboard_enabled: true)
      get :public_dashboard, params: { facility_id: facility.url_name, token: "invalidtoken" }
      expect(response).to be_not_found
    end
  end
end
