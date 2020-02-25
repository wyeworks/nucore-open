# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing training a request", feature_setting: { training_requests: true, reload_routes: true } do
  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:training_request) { create(:training_request) }
  let(:facility) { training_request.product.facility }
  let(:instrument) { training_request.product }
  let(:user) { training_request.user }

  before { login_as director }

  it "can remove a training request" do
    visit facility_training_requests_path(facility)

    expect(page).to have_content(user.email)

    click_button "Remove"

    expect(page).not_to have_content(user.email)
    expect(page).to have_content("There are no outstanding training requests.")
  end
end
