# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FacilityProductNotifications" do
  let(:facility) { create(:setup_facility) }

  shared_examples "requires authentication" do
    it "requires authentication" do
      action.call

      expect(response).to be_redirect
      expect(response.location).to eq(new_user_session_url)
    end
  end

  shared_examples "forbids non-admin user" do
    it "returns forbidden for facility director" do
      login_as create(:user, :facility_director, facility:)
      action.call

      expect(response).to be_forbidden
    end
  end

  describe "index" do
    let(:action) { -> { get list_facility_product_notifications_path(facility) } }

    it_behaves_like "requires authentication"
    it_behaves_like "forbids non-admin user"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }

      it "renders the index page" do
        action.call

        expect(response).to have_http_status(:ok)
      end

      it "displays empty message when no notifications" do
        action.call

        expect(page).to have_content("No product notifications have been created")
        expect(page).to have_link(
          "Add Product Notification",
          href: new_facility_product_notification_path(facility),
        )
      end

      context "with product notifications" do
        let!(:product_notification) { create(:product_notification, facility:, name: "Some Notification") }

        it "lists product notifications" do
          action.call

          expect(page).to have_content("Some Notification")
          expect(page).to have_content("Time Slot Available")
          expect(page).to have_link(
            href: facility_product_notification_path(facility, product_notification),
          )
        end

        it "shows users count" do
          product_notification.update(users_count: 10)

          action.call

          expect(page).to have_content("Some Notification • Time Slot Available • 10 Users")
        end
      end
    end
  end

  describe "show" do
    let(:notification) { create(:product_notification, facility:, name: "Some Notification") }
    let(:action) { -> { get facility_product_notification_path(facility, notification) } }

    it_behaves_like "requires authentication"
    it_behaves_like "forbids non-admin user"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }

      it "renders the show page" do
        action.call

        expect(response).to have_http_status(:ok)
      end

      it "displays notification details" do
        action.call

        expect(page).to have_content("Some Notification")
        expect(page).to have_link(
          "Edit", href: edit_facility_product_notification_path(facility, notification),
        )
      end

      it "displays no products message" do
        action.call

        expect(page).to have_content("No products added")
      end

      it "displays no users message" do
        action.call

        expect(page).to have_content("No users added")
      end

      it "lists associated products" do
        product = create(:instrument, facility:)
        notification.products << product

        action.call

        expect(page).to have_content(product.name)
      end

      it "lists associated users" do
        user = create(:user)
        notification.users << user

        action.call

        expect(page).to have_content(user.name)
        expect(page).to have_content("(#{user.username})")
      end
    end
  end
end
