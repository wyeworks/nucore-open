require "rails_helper"

RSpec.describe ErrorsController, type: :controller do
  describe "GET #not_found" do
    it "renders the 'not_found' template with a 404 status" do
      get :not_found
      expect(response).to have_http_status(:not_found)
      expect(response).to render_template("not_found")
    end
  end

  describe "GET #internal_server_error" do
    it "renders the 'internal_server_error' template with a 500 status" do
      get :internal_server_error
      expect(response).to have_http_status(:internal_server_error)
      expect(response).to render_template("internal_server_error")
    end
  end

  describe "GET #forbidden" do
    context "when the exception is NUCore::NotPermittedWhileActingAs" do
      before do
        request.env["action_dispatch.exception"] = NUCore::NotPermittedWhileActingAs.new
      end

      it "renders the 'acting_error' template with a 403 status" do
        get :forbidden
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("acting_error")
      end
    end

    context "when the user is logged in" do
      before do
        sign_in create(:user)
      end

      it "renders the 'forbidden' template with a 403 status" do
        get :forbidden
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template("forbidden")
      end
    end

    context "when the user is not logged in" do
      it "redirects to the login page and stores the original location" do
        get :forbidden
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
