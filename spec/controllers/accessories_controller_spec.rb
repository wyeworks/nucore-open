# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe AccessoriesController do
  render_views
  before(:all) { create_users }

  let(:instrument) { create(:setup_instrument, :always_available) }
  let(:facility) { instrument.facility }
  let(:quantity_accessory) { create(:accessory, parent: instrument, facility: facility) }
  let(:auto_accessory) { create(:time_based_accessory, parent: instrument, scaling_type: "auto", facility: facility) }
  let(:manual_accessory) { create(:time_based_accessory, parent: instrument, scaling_type: "manual", facility: facility) }
  let(:reservation) { create(:purchased_reservation, product: instrument, reserve_start_at: 1.hour.ago) }
  let(:order_detail) { reservation.order_detail }
  let(:order) { order_detail.order }
  let(:new_order_status) { OrderStatus.new_status }

  before :each do
    order_detail.change_status! new_order_status
    @authable = facility
    @params = { order_id: order.id, order_detail_id: order_detail.id }
  end

  describe "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_operators_only {}

    # facility admin specs cover the inner workings
    context "as the user who made the reservation" do
      before :each do
        sign_in order.user
        do_request
      end

      it "has access" do
        expect(response).to be_successful
      end
    end

    context "as a facility admin" do
      before :each do
        @params[:facility_id] = facility.id
        # make sure accessories are initialized
        quantity_accessory
        auto_accessory
        manual_accessory

        sign_in FactoryBot.create(:user, :facility_director, facility: facility)
      end

      describe "a completed reservation" do
        before do
          reservation.update_attributes(actual_start_at: 1.hour.ago, actual_end_at: 30.minutes.ago)
          do_request
        end

        it "has all three accessories" do
          expect(assigns(:order_details).size).to eq(3)
        end

        it "defaults to a quantity of 1 for quantity" do
          od = assigns(:order_details).find { |od| od.product == quantity_accessory }
          expect(od.quantity).to eq(1)
        end

        it "defaults to the reservation time for auto-scaled" do
          od = assigns(:order_details).find { |od| od.product == auto_accessory }
          expect(od.quantity).to eq(30)
        end

        it "defaults to the reservation duration for manual scaled" do
          od = assigns(:order_details).find { |od| od.product == manual_accessory }
          expect(od.quantity).to eq(30)
        end
      end

      describe "an ongoing reservation" do
        before do
          reservation.update_attributes!(actual_start_at: 37.minutes.ago, actual_end_at: nil)
          do_request
        end

        it "has all three accessories" do
          expect(assigns(:order_details).size).to eq(3)
        end

        it "defaults to a quantity of 1 for quantity" do
          od = assigns(:order_details).find { |od| od.product == quantity_accessory }
          expect(od.quantity).to eq(1)
        end

        it "defaults to the reservation time for auto-scaled" do
          od = assigns(:order_details).find { |od| od.product == auto_accessory }
          expect(od.quantity).to eq(37)
        end

        it "defaults to the reservation duration for manual scaled" do
          od = assigns(:order_details).find { |od| od.product == manual_accessory }
          expect(od.quantity).to eq(37)
        end
      end
    end

    context "with a soft-deleted accessory association" do
      before :each do
        accessory = manual_accessory
        instrument.product_accessories.first.soft_delete
        instrument.product_accessories.create(accessory: accessory, scaling_type: "auto")

        expect(instrument.reload.product_accessories.count).to eq(1)
        expect(ProductAccessory.where(product_id: instrument.id, accessory_id: accessory.id).count).to eq(2)
      end

      it "the same accessory can be re-added" do
        maybe_grant_always_sign_in :admin
        do_request

        expect(assigns(:order_details)).to be_one
        expect(assigns(:order_details).first.scaling_type).to eq("auto")
      end
    end
  end

  describe "create" do
    before :each do
      @method = :post
      @action = :create
    end

    context "as the user who made the reservation" do
      before :each do
        reservation.update_attributes(actual_start_at: 1.hour.ago, actual_end_at: 30.minutes.ago)
        sign_in order.user
      end

      describe "adding a quantity-based accessory" do
        before :each do
          @params.merge! accessories: {
            quantity_accessory.id.to_s => {
              quantity: "3",
              enabled: "true",
            },
          }
        end

        it "creates the order detail" do
          do_request
          expect(assigns(:order_details).size).to eq(1)
          expect(assigns(:order_details).first).to be_persisted
        end

        it "allows a soft deleted accessory to be accessed through the order detail" do
          do_request
          expect(assigns(:order_details).size).to eq 1
          detail = assigns(:order_details).first
          expect(detail.product_accessory.accessory).to eq quantity_accessory
          expect(instrument.product_accessories.size).to eq 1
          expect(instrument.product_accessories.first.accessory).to eq quantity_accessory
          instrument.product_accessories.first.soft_delete
          expect(instrument.product_accessories.size).to eq 0
          expect(detail.reload.product_accessory.accessory).to eq quantity_accessory
        end

        it "creates the order detail with the correct quantity" do
          do_request
          expect(assigns(:order_details).first.quantity).to eq(3)
        end

        it "creates the order detail as the same status as the parent" do
          do_request
          expect(assigns(:order_details).first.order_status).to eq(order_detail.order_status)
        end

        it "creates the order detail as completed if the original is" do
          order_detail.backdate_to_complete!
          do_request
          expect(assigns(:order_details).first.reload).to be_complete
          expect(assigns(:order_details).first).to be_fulfilled_at
        end

        context "adding a disabled accessory" do
          before :each do
            @params[:accessories][quantity_accessory.id.to_s][:enabled] = "false"
          end

          it "does not add the accessory" do
            expect(assigns(:order_details)).to be_blank
          end
        end

        context "trying to add a negative quantity" do
          before :each do
            @params[:accessories][quantity_accessory.id.to_s][:quantity] = "-1"
            do_request
          end

          it "has an error on the order detail" do
            expect(assigns(:order_details).first.errors).to be_include(:quantity)
          end

          it "does not save the order detail" do
            expect(assigns(:order_details).first).to be_new_record
          end
        end
      end

      describe "adding a manual-scaled accessory" do
        before :each do
          @params[:accessories] = {
            manual_accessory.id.to_s => {
              quantity: "30",
              enabled: "true",
            },
          }
        end

        it "creates the order detail" do
          do_request
          expect(assigns(:order_details).size).to eq(1)
          expect(assigns(:order_details).first).to be_persisted
        end

        it "creates the order detail with the correct quantity" do
          do_request
          expect(assigns(:order_details).first.quantity).to eq(30)
        end

        it "creates the order detail as the same status as the parent" do
          do_request
          expect(assigns(:order_details).first.order_status).to eq(order_detail.order_status)
        end

        it "creates the order detail as completed if the original is" do
          order_detail.backdate_to_complete!
          do_request
          expect(assigns(:order_details).first.reload).to be_complete
          expect(assigns(:order_details).first).to be_fulfilled_at
        end

        context "adding a disabled accessory" do
          before :each do
            @params[:accessories][manual_accessory.id.to_s][:enabled] = "false"
          end

          it "does not add the accessory" do
            expect(assigns(:order_details)).to be_blank
          end
        end
      end

      describe "adding an autoscaled accessory" do
        before :each do
          @params[:accessories] = {
            auto_accessory.id.to_s => {
              quantity: "40",
              enabled: "true",
            },
          }
        end

        it "creates the order detail" do
          do_request
          expect(assigns(:order_details).size).to eq(1)
          expect(assigns(:order_details).first).to be_persisted
        end

        it "creates the order detail with the length, no matter what the parameter" do
          do_request
          expect(assigns(:order_details).first.quantity).to eq(30)
        end

        it "creates the order detail as the same status as the parent" do
          do_request
          expect(assigns(:order_details).first.order_status).to eq(order_detail.order_status)
        end

        it "creates the order detail as completed if the original is" do
          order_detail.backdate_to_complete!
          do_request
          expect(assigns(:order_details).first).to be_complete
        end

        context "adding a disabled accessory" do
          before :each do
            @params[:accessories][auto_accessory.id.to_s][:enabled] = "false"
          end

          it "does not add the accessory" do
            expect(assigns(:order_details)).to be_blank
          end
        end

      end
    end
  end
end
