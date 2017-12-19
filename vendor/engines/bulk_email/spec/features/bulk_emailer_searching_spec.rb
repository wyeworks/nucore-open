require "rails_helper"

RSpec.describe "Bulk email search" do
  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:training_request) { create(:training_request) }
  let(:facility) { training_request.product.facility }
  let(:instrument) { training_request.product }
  let(:user) { training_request.user }

  before { login_as director }

  it "returns matching results" do
    visit facility_bulk_email_path(facility)

    check "Authorized Users"

    click_button "Search"

    expect(page).to have_content("No users found")

    check "Users on Training Request List"

    click_button "Search"

    expect(page).to have_content(user.email)
  end
end
