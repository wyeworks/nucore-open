# frozen_string_literal: true

require "rails_helper"

RSpec.describe SamlAuthentication::SessionsController, type: :controller do
  before do
    # This prevents any Authentication errors like mismatched hosts or signatures since
    # the fixture was a response captured during development.
    allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:is_valid?).and_return(true)
  end

  describe "#create" do
    let(:saml_response) do
      Base64.encode64(File.read(File.expand_path("../../fixtures/saml_login_response.xml", __dir__)))
    end

    before do
      request.env["devise.mapping"] = Devise.mappings[:user]
      # Our response fixure is old, so don't worry about it
      allow(Devise).to receive(:allowed_clock_drift_in_seconds).and_return(1000.years)
    end

    describe "the user does not exist already" do
      it "does not log the user in" do
        post :create, params: { SAMLResponse: saml_response }
        expect(controller.current_user).to be_blank
      end

      it "renders" do
        expect(response).to be_successful
      end
    end

    describe "the user exists" do
      let!(:user) { create(:user, username: "jhanggi", email: "jason@tablexi.com", first_name: "Jaason", last_name: "Hangii") }

      it "logs in the user and sets the first/last names" do
        post :create, params: { SAMLResponse: saml_response }

        expect(controller.current_user).to eq(user)
      end

      it "updpates the name" do
        post :create, params: { SAMLResponse: saml_response }

        expect(controller.current_user.first_name).to eq("Jason")
        expect(controller.current_user.last_name).to eq("Hanggi")
      end

      it "does not update the email address" do
        post :create, params: { SAMLResponse: saml_response }
        expect(user.reload.email).to eq("jason@tablexi.com")
      end

      it "updates the emplid" do
        post :create, params: { SAMLResponse: saml_response }
        expect(user.reload.umass_emplid).to eq("32564503")
      end
    end
  end
end
