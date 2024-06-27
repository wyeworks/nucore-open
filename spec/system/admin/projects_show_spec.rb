# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects show", feature_setting: { cross_core_order_view: true } do
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
        visit facility_project_path(facility, active_project)
      end

      it "shows the project" do
        expect(page).to have_content(active_project.name)
      end

      it "shows the order details" do
        expect(page).to have_content(active_project_order.order_details.first.id)
      end

      it "shows Edit button" do
        expect(page).to have_link("Edit")
      end

      it "doesn't show account info" do
        expect(page).not_to have_content(active_project_order.account.to_s)
      end

      it "navigates to order" do
        click_link active_project_order.id

        expect(page).to have_content(active_project_order.id)
      end
    end

    context "from another facility" do
      let!(:active_project2) { create(:project, facility: facility2) }

      before do
        visit facility_project_path(facility, active_project2)
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
          visit facility_project_path(facility, cross_core_project)
        end

        it "shows the project" do
          expect(page).to have_content(cross_core_project.name)
        end

        it "shows the order details" do
          expect(page).to have_content(originating_order_facility1.order_details.first.id)
          expect(page).to have_content(cross_core_orders[0].order_details.first.id)
          expect(page).to have_content(cross_core_orders[1].order_details.first.id)
        end

        it "shows other facility's orders as text" do
          expect(page).not_to have_link(cross_core_orders[0].id)
          expect(page).not_to have_link(cross_core_orders[1].id)

          expect(page).to have_content(cross_core_orders[0].id)
          expect(page).to have_content(cross_core_orders[1].id)
        end

        it "shows Edit button" do
          expect(page).to have_link("Edit")
        end

        it "doesn't show account info" do
          expect(page).not_to have_content(active_project_order.account.to_s)
        end

        it "navigates to original order" do
          click_link originating_order_facility1.id

          expect(page).to have_content(originating_order_facility1.id)
          expect(page).to have_content(facility2.name)
          expect(page).to have_content(facility3.name)
        end
      end

      context "originating from another facility" do
        before do
          visit facility_project_path(facility, cross_core_project2)
        end

        it "shows the project" do
          expect(page).to have_content(cross_core_project2.name)
        end

        it "shows the order details" do
          expect(page).to have_content(originating_order_facility2.order_details.first.id)
          expect(page).to have_content(cross_core_orders[2].order_details.first.id)
          expect(page).to have_content(cross_core_orders[3].order_details.first.id)
        end

        it "shows Edit button" do
          expect(page).to have_link("Edit")
        end

        it "doesn't show account info" do
          expect(page).not_to have_content(active_project_order.account.to_s)
        end

        it "shows other facility's orders as text" do
          expect(page).not_to have_link(originating_order_facility2.id)
          expect(page).not_to have_link(cross_core_orders[3].id)

          expect(page).to have_content(originating_order_facility2.id)
          expect(page).to have_content(cross_core_orders[3].id)
        end

        it "navigates to facility order" do
          click_link cross_core_orders[2].id

          expect(page).to have_content(cross_core_orders[2].id)
          expect(page).to have_content(facility2.name)
          expect(page).to have_content(facility3.name)
        end
      end
    end

    context "not involving current facility" do
      context "originating from another facility" do
        before do
          visit facility_project_path(facility, cross_core_project3)
        end

        it "does not show the project" do
          expect(page).to have_content("Sorry, you don't have permission to access this page.")
        end
      end
    end
  end
end
