# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an estimate" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }

  before { login_as director }

  it "can create an estimate" do
    visit facility_estimates_path(facility)

    expect(page).to have_selector("#admin_estimates_tab")
    expect(page).to have_content facility.to_s

    click_link "Add Estimate"
    expect(page).to have_content "Create an Estimate"

    fill_in "Name", with: "Test Estimate"
    fill_in "Expires at", with: 1.month.from_now.strftime("%m/%d/%Y")
    fill_in "Note", with: "This is a test estimate"
    select director.to_s, from: "User"

    click_button "Add Estimate"

    expect(page).to have_content "Estimate successfully created"
    expect(page).to have_content "Estimate ##{Estimate.last.id} - Test Estimate"
    expect(page).to have_content "This is a test estimate"
    expect(page).to have_content 1.month.from_now.strftime("%m/%d/%Y")
    expect(page).to have_content director.full_name
  end
end
