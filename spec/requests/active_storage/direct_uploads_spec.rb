# frozen_string_literal: true

require "rails_helper"

RSpec.describe "direct uploads" do
  let(:action) { -> { post rails_direct_uploads_path } }

  it "requires login" do
    action.call

    expect(response).to have_http_status(:found)
    expect(response.location).to eq(new_user_session_url)
  end

  context "with logged in user" do
    before { login_as create(:user) }

    it "does not return unauthorized" do
      action.call

      expect(response).to have_http_status(:bad_request)
    end
  end
end
