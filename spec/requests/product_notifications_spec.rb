# frozen_string_literal: true

require "rails_helper"

RSpec.describe "product_notifications" do
  describe "show" do
    let(:product) { create(:setup_instrument) }
    let(:facility) { product.facility }
    let(:action) do
      lambda do
        get facility_product_notifications_path(facility, product)
      end
    end

    before { login_as create(:user, :administrator) }

    context "when product notification exist" do
      before do
        product.create_product_notification(
          notification_type: "slot_available",
          recipient_source: "access_list",
        )
      end

      it "shows slot available section" do
        action.call

        expect(page).to have_content("Reservation canceled: time slot becomes available")
      end
    end

    context "when product notification not present" do
      it "does not show slot available section" do
        action.call

        expect(page).not_to have_content("slot becomes available")
      end
    end
  end
  describe "edit" do
    let(:facility) { product.facility }
    let(:action) do
      lambda do
        get edit_facility_product_notifications_path(facility, product)
      end
    end
    let(:recipient_source_field_name) do
      "product[product_notification_attributes][recipient_source]"
    end

    before { login_as create(:user, :administrator) }

    context "when product is an instrument" do
      let(:product) { create(:setup_instrument) }

      it "shows product notifications form" do
        action.call

        expect(page).to have_field(recipient_source_field_name)
      end
    end

    context "when product is not an instrument" do
      let(:product) { create(:setup_item) }

      it "does not show product notifications form" do
        action.call

        expect(page).not_to have_field(recipient_source_field_name)
      end
    end
  end

  describe "update" do
    let(:product) { create(:setup_instrument) }
    let(:facility) { product.facility }
    let(:action) do
      lambda do
        put(facility_product_notifications_path(facility, product), params:)
      end
    end

    before { login_as create(:user, :administrator) }

    describe "product_notifications update" do
      let(:params) do
        {
          product: {
            product_notification_attributes:,
          }
        }
      end

      context "when notification does not exist" do
        let(:product_notification_attributes) do
          { notification_type: "slot_available", recipient_source: "access_list" }
        end

        it "creates a product notification with correct attributes" do
          expect { action.call }.to(
            change do
              ProductNotification.find_by(
                product:,
                notification_type: "slot_available",
                recipient_source: "access_list",
              )
            end.from(nil).to(ProductNotification)
          )
        end
      end

      context "when it exists" do
        let(:product_notification) do
          product.create_product_notification(
            notification_type: "slot_available",
            recipient_source: "access_list",
          )
        end
        let(:product_notification_attributes) do
          {
            id: product_notification.id,
            notification_type: "slot_available",
            recipient_source: "reservations",
            reservation_days: 10
          }
        end

        it "updates existing product notification" do
          expect { action.call }.to(
            change do
              product_notification.reload.recipient_source
            end.from("access_list").to("reservations")
          )
        end
      end

      context "when disabled" do
        let(:product_notification) do
          product.create_product_notification(
            notification_type: "slot_available",
            recipient_source: "access_list",
          )
        end
        let(:product_notification_attributes) do
          {
            id: product_notification.id,
            _destroy: true,
          }
        end

        it "destroys the product notification" do
          expect { action.call }.to(
            change do
              product.reload.product_notification
            end.from(product_notification).to(nil)
          )
        end
      end
    end
  end
end
