# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetail do
  let(:instrument) { FactoryBot.create(:setup_instrument, :timer) }
  let(:facility) { instrument.facility }
  let(:reservation) { FactoryBot.create(:completed_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail.tap { |od| od.update(note: "original", ordered_at: 1.day.ago) } }
  let(:accessorizer) { Accessories::Accessorizer.new(order_detail) }

  before :each do
    order_detail.backdate_to_complete!(Time.zone.now)
  end

  shared_examples_for "an accessory's order detail" do
    it "belongs to the parent" do
      expect(accessory_order_detail.parent_order_detail).to eq(order_detail)
    end

    it "belongs to the same order" do
      expect(accessory_order_detail.order).to eq(order_detail.order)
    end

    it "is for the correct product" do
      expect(accessory_order_detail.product).to eq(accessory)
    end

    it "is for the same account" do
      expect(accessory_order_detail.account).to eq(order_detail.account)
    end

    it "is complete" do
      expect(accessory_order_detail).to be_complete
      expect(accessory_order_detail.order_status.name).to eq("Complete")
    end

    it "has pricing" do
      expect(accessory_order_detail.actual_cost).to be
    end

    it "changes the child's account when changing the parent's account" do
      new_account = FactoryBot.create(:setup_account, owner: order_detail.user)
      order_detail.update_attributes(account: new_account)
      expect(accessory_order_detail.reload.account).to eq new_account
    end

    it "takes the ordered_at of the original order" do
      expect(accessory_order_detail.ordered_at).to eq(order_detail.ordered_at)
    end
  end

  context "quantity based accessory" do
    let(:accessory) { create(:accessory, parent: instrument, facility: facility) }

    let!(:accessory_order_detail) { accessorizer.add_accessory(accessory) }
    it_behaves_like "an accessory's order detail"

    context "where the reservation time changes" do
      before :each do
        accessory_order_detail.update_attributes(quantity: 1)
        reservation.update_attributes(reserve_end_at: reservation.reserve_end_at + 30.minutes)
      end

      it "does not update the quantity" do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end
  end

  context "manual scaled accessory" do
    let(:accessory) { create(:time_based_accessory, parent: instrument, scaling_type: "manual", facility: facility) }
    let(:accessory_order_detail) { accessorizer.add_accessory(accessory) }

    it_behaves_like "an accessory's order detail"

    it "has the number of actual usage time as the quantity" do
      expect(accessory_order_detail.quantity).to eq(reservation.actual_duration_mins)
    end

    it "defaults to 1 if less than a minute" do
      reservation.update_attributes(actual_end_at: reservation.actual_start_at + 29.seconds)
      expect(reservation.actual_duration_mins).to eq(1)
      expect(accessory_order_detail.reload.quantity).to eq(1)
    end

    context "where the reservation time changes" do
      before :each do
        accessory_order_detail.update_attributes(quantity: 1)
        reservation.update_attributes(reserve_end_at: reservation.reserve_end_at + 30.minutes)
      end

      it "does not update the quantity" do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end

    context "where the actual time changes" do
      before :each do
        accessory_order_detail.update_attributes(quantity: 1)
        reservation.update_attributes(actual_end_at: reservation.actual_end_at + 30.minutes)
      end

      it "does not update the quantity" do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end
  end

  context "auto scaled accessory" do
    let(:accessory) { create(:time_based_accessory, parent: instrument, scaling_type: "auto", facility: facility) }
    # reload in order to avoid timestamp truncation causing false-positives on `changes`
    let!(:accessory_order_detail) { accessorizer.add_accessory(accessory).reload }

    it_behaves_like "an accessory's order detail"

    it "has the number of actual usage time as the quantity" do
      expect(accessory_order_detail.quantity).to eq(reservation.actual_duration_mins)
    end

    it "defaults to 1 if less than a minute" do
      reservation.update_attributes(actual_end_at: reservation.actual_start_at + 29.seconds)
      expect(reservation.actual_duration_mins).to eq(1)
      expect(accessory_order_detail.reload.quantity).to eq(1)
    end

    context "where the reservation time changes" do
      before :each do
        reservation.update_attributes(reserve_end_at: reservation.reserve_end_at + 30.minutes)
      end

      it "does not update the quantity" do
        expect(accessory_order_detail.reload.quantity).to eq(60)
      end

      it "does not mark anything as changed" do
        expect(order_detail.updated_children).to be_empty
      end
    end

    context "where the actual time changes" do
      before :each do
        reservation.update_attributes(actual_end_at: reservation.actual_end_at + 30.minutes)
      end

      it "updates the quantity" do
        expect(accessory_order_detail.reload.quantity).to eq(90)
      end

      it "marks as changed" do
        # accessory_order_detail might be decorated at this point, so reload
        expect(order_detail.updated_children).to eq([accessory_order_detail.reload])
      end
    end
  end

  context "accessory does not have a price policy" do
    let(:accessory) { create(:accessory, parent: instrument, facility: facility) }
    let(:accessory_order_detail) { accessorizer.add_accessory(accessory) }
    before :each do
      accessory.price_policies.destroy_all
    end

    it "makes the order detail complete" do
      expect(accessory_order_detail.order_status.name).to eq("Complete")
    end

    it "makes the order detail a problem order" do
      expect(accessory_order_detail).to be_problem_order
    end
  end

  describe "sorting" do
    let(:accessory) { create(:accessory, parent: instrument, facility: facility) }
    let(:order) { order_detail.order }
    let(:order_details) { order.order_details }
    let!(:interim_order_detail) { order.add(accessory, 1, note: "interim") }
    let!(:accessory_order_detail) { accessorizer.add_accessory(accessory, note: "accessory") }

    # Ensure
    it "builds the details in the right order" do
      expect(order_details.order(:id).pluck(:note)).to eq(%w(original interim accessory))
      expect(order_details.order(:id).pluck(:parent_order_detail_id)).to eq([nil, nil, order_detail.id])
    end

    it "puts the parent together with its child with the parent before the child" do
      expect(order_details.ordered_by_parents.pluck(:note)).to eq(%w(original accessory interim))
    end
  end
end
