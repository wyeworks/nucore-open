# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects search" do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let!(:active_project) { create(:project, facility:) }
  let!(:inactive_project) { create(:project, :inactive, facility:) }

  before do
    login_as facility_administrator

    visit facility_projects_path(facility)
  end

  context "by default" do
    it "shows only non cross core active projects for current facility" do
      expect(page).not_to have_content(cross_core_project.name)
      expect(page).not_to have_content(cross_core_project2.name)
      expect(page).not_to have_content(cross_core_project3.name)

      expect(page).to have_content(active_project.name)
      expect(page).not_to have_content(inactive_project.name)
    end
  end

  context "when Active and Cross Core are selected" do
    before do
      select "Active", from: "Active/Inactive"
      select "Yes", from: "Cross Core"
      click_button "Filter"
    end

    it "shows only cross core active projects for current facility" do
      expect(page).to have_content(cross_core_project.name)
      expect(page).to have_content(cross_core_project2.name)

      expect(page).not_to have_content(cross_core_project3.name)

      expect(page).not_to have_content(active_project.name)
      expect(page).not_to have_content(inactive_project.name)
    end
  end

  context "when Inactive and Cross Core are selected" do
    before do
      select "Inactive", from: "Active/Inactive"
      select "Yes", from: "Cross Core"
      click_button "Filter"
    end

    it "shows only cross core inactive projects for current facility" do
      expect(page).not_to have_content(cross_core_project.name)
      expect(page).not_to have_content(cross_core_project2.name)
      expect(page).not_to have_content(cross_core_project3.name)

      expect(page).not_to have_content(active_project.name)
      expect(page).not_to have_content(inactive_project.name)
    end
  end

  context "when Inactive and non Cross Core are selected" do
    before do
      select "Inactive", from: "Active/Inactive"
      select "No", from: "Cross Core"
      click_button "Filter"
    end

    it "shows only non cross core inactive projects for current facility" do
      expect(page).not_to have_content(cross_core_project.name)
      expect(page).not_to have_content(cross_core_project2.name)
      expect(page).not_to have_content(cross_core_project3.name)

      expect(page).not_to have_content(active_project.name)
      expect(page).to have_content(inactive_project.name)
    end
  end
end
