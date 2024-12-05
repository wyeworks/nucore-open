# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects edit", feature_setting: { cross_core_order_view: true } do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let!(:active_project) { create(:project, facility:) }
  let!(:inactive_project) { create(:project, :inactive, facility:) }
  let!(:active_project_order) { create(:purchased_order, product: item, account: accounts.first) }
  let!(:inactive_project_order) { create(:purchased_order, product: item, account: accounts.first) }

  before do
    login_as facility_administrator

    active_project_order.order_details.first.update(project: active_project)
    inactive_project_order.order_details.first.update(project: inactive_project)
  end

  context "non cross core project" do
    context "from current facility" do
      before do
        visit edit_facility_project_path(facility, active_project)
      end

      it "fields are enabled" do
        expect(page).to have_field("Name", disabled: false)
        expect(page).to have_field("Active", disabled: false)
      end

      it "updates project" do
        fill_in "Name", with: "New Name"
        fill_in "Description", with: "New Description"

        click_button "Update Project"

        expect(page).to have_content("Project New Name was updated.")
        expect(current_path).to eq(facility_project_path(facility, active_project))
      end
    end

    context "from another facility" do
      let!(:active_project2) { create(:project, facility: facility2) }

      before do
        visit edit_facility_project_path(facility, active_project2)
      end

      it "does not show the project" do
        expect(page).not_to have_content(active_project2.name)
        expect(page).to have_content("Sorry, you don't have permission to access this page.")
      end
    end
  end

  context "cross core project" do
    context "involving current facility" do
      context "originating from current facility" do
        before do
          visit edit_facility_project_path(facility, cross_core_project)
        end

        it "fields are disabled" do
          expect(page).to have_field("Name", disabled: true)
          expect(page).to have_field("Active", disabled: true)
        end

        it "updates project" do
          fill_in "Description", with: "New Description"

          click_button "Update Project"

          expect(page).to have_content("Project #{cross_core_project.name} was updated.")
          expect(page).to have_content("New Description")
          expect(current_path).to eq(facility_project_path(facility, cross_core_project))
        end
      end

      context "originating from another facility" do
        before do
          visit edit_facility_project_path(facility, cross_core_project2)
        end

        it "fields are disabled" do
          expect(page).to have_field("Name", disabled: true)
          expect(page).to have_field("Active", disabled: true)
        end

        it "updates project" do
          fill_in "Description", with: "New Description"

          click_button "Update Project"

          expect(page).to have_content("Project #{cross_core_project2.name} was updated.")
          expect(page).to have_content("New Description")
          expect(current_path).to eq(facility_project_path(facility, cross_core_project2))
        end
      end
    end

    context "not involving current facility" do
      context "originating from another facility" do
        before do
          visit edit_facility_project_path(facility, cross_core_project3)
        end

        it "does not show the project" do
          expect(page).to have_content("Sorry, you don't have permission to access this page.")
        end
      end
    end
  end
end
