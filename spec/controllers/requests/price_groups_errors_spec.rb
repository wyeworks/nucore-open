require "rails_helper"

RSpec.describe "PriceGroups Error Handling", type: :request do
  let(:facility) { create(:facility) }
  let(:price_group) { create(:price_group, facility: facility) }

  describe "GET #show" do
    context "when the price group is not found" do
      it "renders the 404 error page" do
        allow(PriceGroup).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        get facility_price_group_path(facility, id: "non-existent-id")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("404 – Not Found")
      end
    end
  end

  describe "GET #users" do
    context "when the user cannot access price group users" do
      before do
        allow(SettingsHelper).to receive(:feature_on?).with(:user_based_price_groups).and_return(false)
        sign_in create(:user, :staff)
      end

      it "renders the 403 error page" do
        get users_facility_price_group_path(facility, price_group)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("403 – Permission Denied")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when trying to delete a global price group" do
      let(:global_price_group) { create(:price_group, :global) }

      it "renders the 404 error page" do
        allow_any_instance_of(PriceGroupsController).to receive(:destroy).and_raise(ActiveRecord::RecordNotFound)
        delete facility_price_group_path(facility, global_price_group)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("404 – Not Found")
      end
    end
  end

  describe "GET #index" do
    context "when an internal server error occurs" do
      before do
        allow_any_instance_of(PriceGroupsController)
          .to receive(:index)
          .and_raise(StandardError, "Simulated Internal Server Error")
      end

      it "renders the 500 error page" do
        get facility_price_groups_path(facility)
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to include("500 – Internal Server Error")
      end
    end
  end
end
