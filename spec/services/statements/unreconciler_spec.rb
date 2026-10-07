# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::Unreconciler do
  let(:user) { create(:user) }
  let(:facility) { create(:setup_facility) }
  let(:statement) { create(:statement, facility:) }
  let(:product) { create(:setup_item, facility:) }
  let(:order) { create(:order, user:, created_by: user.id, facility:) }

  let(:service) { described_class.new(statement, user) }

  def create_reconciled_order_detail(deposit_number:, reconciled_note:)
    order_detail = create(
      :order_detail, :completed,
      order:, product:, actual_cost: 10, actual_subsidy: 0
    )
    statement.add_order_detail(order_detail)
    statement.save!
    order_detail.update!(
      state: "reconciled",
      order_status: OrderStatus.reconciled,
      reconciled_at: 1.day.ago,
      deposit_number:,
      reconciled_note:,
    )
    order_detail
  end

  let!(:order_detail1) { create_reconciled_order_detail(deposit_number: "TX-1", reconciled_note: "Note 1") }
  let!(:order_detail2) { create_reconciled_order_detail(deposit_number: "TX-2", reconciled_note: "Note 2") }

  def log_event
    LogEvent.where(loggable: statement, event_type: :unreconciled).last
  end

  describe "#unreconcile" do
    it "returns the number of unreconciled order details" do
      expect(service.unreconcile).to eq(2)
    end

    it "moves every order detail back to complete" do
      service.unreconcile

      expect(order_detail1.reload.state).to eq("complete")
      expect(order_detail2.reload.state).to eq("complete")
    end

    it "clears the reconciliation fields" do
      service.unreconcile

      [order_detail1, order_detail2].each do |order_detail|
        order_detail.reload
        expect(order_detail.reconciled_at).to be_nil
        expect(order_detail.deposit_number).to be_nil
        expect(order_detail.reconciled_note).to be_nil
      end
    end

    it "leaves the statement unreconciled" do
      service.unreconcile

      expect(statement.reload.status).to eq(:unreconciled)
    end

    it "logs a single statement.unreconciled event" do
      expect { service.unreconcile }.to change {
        LogEvent.where(loggable: statement, event_type: :unreconciled).count
      }.by(1)
    end

    it "records the acting user on the log event" do
      service.unreconcile

      expect(log_event.user).to eq(user)
    end

    it "records the Transaction IDs that were cleared" do
      service.unreconcile

      expect(log_event.metadata["deposit_numbers"]).to contain_exactly("TX-1", "TX-2")
    end

    it "records the Reconciliation Notes that were cleared" do
      service.unreconcile

      expect(log_event.metadata["reconciled_notes"]).to contain_exactly("Note 1", "Note 2")
    end

    it "deduplicates repeated values" do
      order_detail2.update!(deposit_number: "TX-1", reconciled_note: "Note 1")

      service.unreconcile

      expect(log_event.metadata["deposit_numbers"]).to eq(["TX-1"])
      expect(log_event.metadata["reconciled_notes"]).to eq(["Note 1"])
    end

    context "when an order detail has no Transaction ID or note" do
      let!(:order_detail3) { create_reconciled_order_detail(deposit_number: nil, reconciled_note: nil) }

      it "unreconciles it too" do
        expect(service.unreconcile).to eq(3)
      end

      it "omits the blank values from the metadata" do
        service.unreconcile

        expect(log_event.metadata["deposit_numbers"]).to contain_exactly("TX-1", "TX-2")
        expect(log_event.metadata["reconciled_notes"]).to contain_exactly("Note 1", "Note 2")
      end
    end

    context "when only some order details are reconciled" do
      before { order_detail2.update!(state: "complete", order_status: OrderStatus.complete) }

      it "only unreconciles the reconciled one" do
        expect(service.unreconcile).to eq(1)
        expect(order_detail1.reload.state).to eq("complete")
      end

      it "only records metadata for the reconciled one" do
        service.unreconcile

        expect(log_event.metadata["deposit_numbers"]).to eq(["TX-1"])
      end
    end

    context "when nothing is reconciled" do
      before do
        [order_detail1, order_detail2].each do |order_detail|
          order_detail.update!(state: "complete", order_status: OrderStatus.complete)
        end
      end

      it "returns 0" do
        expect(service.unreconcile).to eq(0)
      end

      it "logs nothing" do
        expect { service.unreconcile }.not_to change(LogEvent, :count)
      end
    end

    context "when one order detail fails to unreconcile" do
      before do
        failing_id = order_detail2.id

        allow_any_instance_of(OrderDetail).to receive(:to_complete_from_reconciled!).and_wrap_original do |method|
          raise ActiveRecord::RecordInvalid, method.receiver if method.receiver.id == failing_id

          method.call
        end
      end

      it "rolls the whole batch back" do
        expect(service.unreconcile).to eq(0)

        order_detail1.reload
        expect(order_detail1.state).to eq("reconciled")
        expect(order_detail1.deposit_number).to eq("TX-1")
      end

      it "reports the error" do
        service.unreconcile

        expect(service.errors.join).to include("Order ##{order_detail2.id}")
      end

      it "logs nothing" do
        expect { service.unreconcile }.not_to change(LogEvent, :count)
      end
    end
  end
end
