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

        expect(page).to have_content("No Product Notifications have been created")
        expect(page).to have_link(
          "Add Product Notification",
          href: new_facility_product_notification_path(facility),
        )
      end

      context "with product notifications" do
        let!(:product_notification) do
          create(:product_notification, facility:, name: "Some Notification")
        end

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

          expect(page).to have_content(
            "Some Notification • Time Slot Available • 10 Users",
          )
        end
      end
    end
  end

  describe "new" do
    let(:action) { -> { get new_facility_product_notification_path(facility) } }

    it_behaves_like "requires authentication"
    it_behaves_like "forbids non-admin user"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }

      it "renders the new page" do
        action.call

        expect(response).to have_http_status(:ok)
      end

      it "displays the form" do
        action.call

        expect(page).to have_content("New Product Notification")
        expect(page).to have_field("product_notification[name]")
        expect(page).to have_field("product_notification[reservation_days]")
      end

      it "loads instruments for selection" do
        instrument = create(:instrument, facility:)
        item = create(:item, facility:)

        action.call

        expect(page).to have_select(
          "product_notification[product_ids][]",
          with_options: [instrument.name],
        )
        expect(page).not_to have_select(
          "product_notification[product_ids][]",
          with_options: [item.name],
        )
      end
    end
  end

  describe "create" do
    let(:params) { {} }
    let(:action) do
      -> { post create_facility_product_notifications_path(facility), params: }
    end

    it_behaves_like "requires authentication"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }
      let(:product_notification_attributes) do
        {
          name: "New Notification",
          reservation_days: 10,
          email_subject: "Some subject",
        }
      end

      context "with valid params" do
        let(:params) do
          {
            product_notification: {
              product_ids: [],
              user_ids: [],
              **product_notification_attributes,
            },
          }
        end

        it "creates a product notification with correct attributes" do
          expect { action.call }.to(
            change do
              ProductNotification.where(product_notification_attributes).count
            end.by(1)
          )
        end

        it "redirects to show" do
          action.call

          expect(response).to redirect_to(
            facility_product_notification_path(facility, ProductNotification.last),
          )
        end

        it "sets a success flash" do
          action.call

          expect(flash[:notice]).to eq("Product Notification created successfully")
        end

        it "creates with the given name and reservation days" do
          action.call

          notification = ProductNotification.last
          expect(notification.name).to eq("New Notification")
          expect(notification.reservation_days).to eq(10)
        end

        it "associates products" do
          instrument = create(:instrument, facility:)
          params[:product_notification][:product_ids] = [instrument.id]

          action.call

          expect(ProductNotification.last.products).to(
            contain_exactly(instrument)
          )
        end

        it "associates users" do
          user = create(:user)
          params[:product_notification][:user_ids] = [user.id]

          action.call

          expect(ProductNotification.last.users).to contain_exactly(user)
        end
      end
    end
  end

  describe "edit" do
    let(:notification) { create(:product_notification, facility:) }
    let(:action) do
      -> { get edit_facility_product_notification_path(facility, notification) }
    end

    it_behaves_like "requires authentication"
    it_behaves_like "forbids non-admin user"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }

      it "renders the edit page" do
        action.call

        expect(response).to have_http_status(:ok)
      end

      it "displays the form with existing name" do
        action.call

        expect(page).to have_content("Edit Product Notification")
        expect(page).to have_field(
          "product_notification[name]",
          with: notification.name,
        )
      end

      it "loads instruments for selection" do
        instrument = create(:instrument, facility:)

        action.call

        expect(page).to have_select(
          "product_notification[product_ids][]",
          with_options: [instrument.name],
        )
      end
    end
  end

  describe "update" do
    let(:notification) { create(:product_notification, facility:) }
    let(:params) { {} }
    let(:action) do
      lambda do
        put facility_product_notification_path(facility, notification), params:
      end
    end

    it_behaves_like "requires authentication"

    context "as an administrator" do
      before { login_as create(:user, :administrator) }

      context "with valid params" do
        let(:params) do
          {
            product_notification: {
              name: "Updated Name",
              reservation_days: 20,
            }
          }
        end

        it "updates the notification" do
          action.call

          notification.reload
          expect(notification.name).to eq("Updated Name")
          expect(notification.reservation_days).to eq(20)
        end

        it "redirects to show" do
          action.call

          expect(response).to redirect_to(
            facility_product_notification_path(facility, notification),
          )
        end

        it "sets a success flash" do
          action.call

          expect(flash[:notice]).to eq("Product Notification updated successfully")
        end

        it "updates associated products" do
          instrument = create(:instrument, facility:)
          params[:product_notification][:product_ids] = [instrument.id]

          action.call

          notification.reload
          expect(notification.products).to contain_exactly(instrument)
        end
      end

      context "when removing all users" do
        let(:user) { create(:user) }
        let(:params) do
          {
            product_notification: {
              name: notification.name,
              reservation_days: notification.reservation_days,
              user_ids: [],
            }
          }
        end

        before do
          notification.users << user
        end

        it "removes all users" do
          action.call

          notification.reload
          expect(notification.users).to be_empty
        end
      end
    end
  end

  describe "show" do
    let(:notification) do
      create(:product_notification, facility:, name: "Some Notification")
    end
    let(:action) do
      -> { get facility_product_notification_path(facility, notification) }
    end

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
          "Edit",
          href: edit_facility_product_notification_path(facility, notification),
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
