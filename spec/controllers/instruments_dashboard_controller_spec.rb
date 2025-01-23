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
      expect { do_request }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "public dashboard" do
    context "when it is not turned on" do
      it_behaves_like "raises specified error", -> { get :public_dashboard, params: { facility_id: facility.url_name, token: "" } }, ActiveRecord::RecordNotFound
    end

    it "allows access with the token" do
      facility.update!(dashboard_enabled: true)
      get :public_dashboard, params: { facility_id: facility.url_name, token: facility.dashboard_token }
      expect(response).to be_successful
    end

    it "does not allow access if the token is wrong" do
      facility.update!(dashboard_enabled: true)
      expect { get :public_dashboard, params: { facility_id: facility.url_name, token: "invalidtoken" } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
