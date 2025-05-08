# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Filtering estimates" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:user1) { create(:user, first_name: "First", last_name: "User") }
  let(:user2) { create(:user, first_name: "Second", last_name: "User") }

  let!(:estimate1) { create(:estimate, facility:, name: "First Estimate", user: user1, created_at: 3.days.ago) }
  let!(:estimate2) { create(:estimate, facility:, name: "Second Estimate", user: user2, created_at: 2.days.ago) }
  let!(:expired_estimate) { create(:estimate, facility:, name: "Expired Estimate", user: user1, created_at: 5.days.ago) }

  before(:each) do
    login_as director

    travel_to_and_return(4.days.ago) do
      expired_estimate.update(expires_at: Time.zone.now)
    end
  end

  it "can filter estimates by user" do
    visit facility_estimates_path(facility)

    expect(page).to have_content "First Estimate"
    expect(page).to have_content "Second Estimate"
    expect(page).to have_content "Expired Estimate"

    select user1.full_name, from: "user_id"
    click_button "Filter"

    expect(page).to have_content "First Estimate"
    expect(page).to have_content "Expired Estimate"
    expect(page).not_to have_content "Second Estimate"
  end

  it "can hide expired estimates" do
    visit facility_estimates_path(facility)

    check "hide_expired"
    click_button "Filter"

    expect(page).to have_content "First Estimate"
    expect(page).to have_content "Second Estimate"
    expect(page).not_to have_content "Expired Estimate"
  end

  it "can search by name" do
    visit facility_estimates_path(facility)

    fill_in "estimate_search", with: "First"
    click_button "Filter"

    expect(page).to have_content "First Estimate"
    expect(page).not_to have_content "Second Estimate"
    expect(page).not_to have_content "Expired Estimate"
  end

  it "can search by ID" do
    visit facility_estimates_path(facility)

    fill_in "estimate_search", with: estimate2.id.to_s
    click_button "Filter"

    expect(page).not_to have_content "First Estimate"
    expect(page).to have_content "Second Estimate"
    expect(page).not_to have_content "Expired Estimate"
  end

  it "can combine filters" do
    visit facility_estimates_path(facility)

    select user1.full_name, from: "user_id"
    check "hide_expired"
    click_button "Filter"

    expect(page).to have_content "First Estimate"
    expect(page).not_to have_content "Second Estimate"
    expect(page).not_to have_content "Expired Estimate"

    # Test that user can clear filters
    click_link "Clear Filters"

    expect(page).to have_content "First Estimate"
    expect(page).to have_content "Second Estimate"
    expect(page).to have_content "Expired Estimate"
  end
end
