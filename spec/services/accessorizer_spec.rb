# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accessories::Accessorizer do
  let(:product) { create(:instrument_with_accessory) }
  let(:quantity_accessory) { product.accessories.first }
  let!(:auto_scaled_accessory) { create(:time_based_accessory, parent: product, scaling_type: "auto") }

  let(:order) { build_stubbed :order }
  let(:reservation) do
    build_stubbed :reservation, reserve_start_at: 30.minutes.ago, reserve_end_at: 1.minute.ago, actual_duration_mins: 30
  end
  let(:child_order_detail) { nil }
  let(:child_order_details) { [child_order_detail].compact }
  let(:order_detail) do
    build_stubbed :order_detail,
                  product: product,
                  order: order,
                  reservation: reservation,
                  child_order_details: child_order_details,
                  attributes: {
                    order_id: order.id,
                  }
  end

  subject(:accessorizer) { described_class.new(order_detail) }

  describe "unpurchased_accessory_order_details" do
    context "when no accessories have been added" do

      it "has both accessories as avaiable" do
        expect(accessorizer.unpurchased_accessories).to eq([quantity_accessory, auto_scaled_accessory])
      end

      it "builds an order detail for both accessories" do
        od1 = double "OD1"
        od2 = double "OD2"
        expect(accessorizer).to receive(:build_accessory_order_detail).with(quantity_accessory).and_return od1
        expect(accessorizer).to receive(:build_accessory_order_detail).with(auto_scaled_accessory).and_return od2
        expect(accessorizer.unpurchased_accessory_order_details).to eq([od1, od2])
      end
    end

    context "when the order already has an accessory" do
      let(:child_order_detail) { build_stubbed :order_detail, product: quantity_accessory, order: order }

      it "only has auto_scaled_accessory as an available accessory" do
        expect(accessorizer.unpurchased_accessories).to eq([auto_scaled_accessory])
      end

      it "builds an order detail or auto_scaled_accessory" do
        od = double
        expect(accessorizer).to receive(:build_accessory_order_detail).with(auto_scaled_accessory).and_return(od)
        expect(accessorizer.unpurchased_accessory_order_details).to eq([od])
      end
    end
  end

  describe "accessory_order_details" do
    context "and it already has an order detail" do
      let(:child_order_detail) { build_stubbed :order_detail, product: quantity_accessory, order: order }

      it "returns the existing detail and builds an orderdetail for the other" do
        od = double "existing", product_accessory: product
        expect(accessorizer).to receive(:build_accessory_order_detail).with(auto_scaled_accessory).and_return(od)
        expect(accessorizer.accessory_order_details).to eq([child_order_detail, od])
      end
    end
  end

  describe "build_accessory_order_detail" do
    context "an invalid accessory" do
      let(:invalid_accessory) { build_stubbed(:product) }
      it "returns nil" do
        od = accessorizer.build_accessory_order_detail(invalid_accessory)
        expect(od).to be_nil
      end
    end

    it "builds an order detail" do
      od = accessorizer.build_accessory_order_detail(quantity_accessory)
      expect(od.product).to eq(quantity_accessory)
      expect(od.parent_order_detail).to eq(order_detail)
      expect(od.order_id).to eq(order.id)
      expect(od.quantity).to eq(1)
      expect(od).to_not be_quantity_as_time
    end
  end

  describe "update_accessorizer_attributes" do
    before do
      allow_any_instance_of(OrderDetail).to receive(:assign_estimated_price)
      allow_any_instance_of(OrderDetail).to receive(:save!)
    end

    context "a quantity accessory" do
      let(:params) do
        ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "true", quantity: "3" })
      end
      context "creating" do
        it "sets the attributes" do
          results = accessorizer.update_accessorizer_attributes(params).order_details
          expect(results.first.product).to eq(quantity_accessory)
          expect(results.first.enabled).to be true
          expect(results.first.quantity).to eq(3)
          expect(allow_any_instance_of(OrderDetail).to receive(:assign_estimated_price))
        end

        context "with a note" do
          let(:params) do
            ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "true", quantity: "3", note: "Test note" })
          end

          it "sets the note attribute" do
            results = accessorizer.update_accessorizer_attributes(params).order_details
            expect(results.first.note).to eq("Test note")
          end
        end

        context "when note is required" do
          before do
            quantity_accessory.update!(user_notes_field_mode: "required")
          end

          context "and note is blank" do
            let(:params) do
              ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "true", quantity: "3", note: "" })
            end

            it "is not valid" do
              results = accessorizer.update_accessorizer_attributes(params)
              expect(results).to_not be_valid
              expect(results.order_details.first.errors[:note]).to be_present
            end
          end

          context "and note is provided" do
            let(:params) do
              ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "true", quantity: "3", note: "Required note" })
            end

            it "is valid" do
              results = accessorizer.update_accessorizer_attributes(params)
              expect(results).to be_valid
              expect(results.order_details.first.note).to eq("Required note")
            end
          end
        end

        context "with an invalid entry" do
          let(:results) { accessorizer.update_accessorizer_attributes(params) }

          it "is not valid" do
            expect(Accessories::UpdateResponse).to receive(:new) { double("UpdateResponse", valid?: false) }
            expect(results).to_not be_valid
          end
        end
      end

      context "updating" do
        let(:child_order_detail) { build(:order_detail, product: quantity_accessory, order: order, quantity: 1) }

        it "updates the attributes" do
          results = accessorizer.update_accessorizer_attributes(params).order_details
          expect(results.first.product).to eq(quantity_accessory)
          expect(results.first.enabled).to be true
          expect(results.first.quantity).to eq(3)
        end
      end

      context "removing" do
        let(:child_order_detail) { build_stubbed :order_detail, product: quantity_accessory, order: order, quantity: 1 }

        let(:params) do
          ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "false", quantity: "3" })
        end

        it "removes the order detail" do
          expect(child_order_detail).to receive(:destroy)
          accessorizer.update_accessorizer_attributes(params)
        end
      end

    end

    context "a completed order" do
      let(:params) do
        ActionController::Parameters.new(quantity_accessory.id.to_s => { enabled: "true", quantity: "3" })
      end
      before do
        reservation.order_detail = order_detail
        allow_any_instance_of(OrderDetail).to receive(:assign_price_policy)
        allow(order_detail).to receive(:state).and_return("complete")
        allow(order_detail).to receive(:fulfilled_at).and_return 1.hour.ago
      end

      it "marks the children as complete" do
        expect_any_instance_of(OrderDetail).to receive(:backdate_to_complete!).with(order_detail.fulfilled_at)
        accessorizer.update_accessorizer_attributes(params).order_details

      end
    end
  end
end
