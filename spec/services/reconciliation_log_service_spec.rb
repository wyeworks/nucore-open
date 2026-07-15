# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconciliationLogService do
  let(:user) { create(:user) }
  let(:facility) { create(:setup_facility) }
  let(:statement) { create(:statement, facility:) }
  let(:order_status_reconciled) { OrderStatus.reconciled }
  let(:order_status_unrecoverable) { OrderStatus.unrecoverable }
  let(:product) { create(:setup_item, facility:) }
  let(:order) { create(:order, user:, created_by: user.id, facility:) }

  let(:order_details) do
    [
      create(:order_detail, statement:, order_status: order_status_reconciled, reconciled_note: "Note 1", product:, order:),
      create(:order_detail, statement:, order_status: order_status_reconciled, reconciled_note: "Note 2", product:, order:),
      create(:order_detail, statement:, order_status: order_status_unrecoverable, unrecoverable_note: "Unrecoverable 1", product:, order:),
    ]
  end

  let(:service) { described_class.new(order_details, user) }

  describe "#log_events" do
    it "creates a log event with metadata" do
      expect { service.log_events }.to change {
        LogEvent.where(loggable: statement, event_type: :closed).count
      }.by(1)
    end

    it "includes reconciled notes in metadata" do
      service.log_events
      log_event = LogEvent.where(loggable: statement, event_type: :closed).last
      expect(log_event.metadata["reconciled_notes"]).to contain_exactly("Note 1", "Note 2")
    end

    it "includes unrecoverable notes in metadata" do
      service.log_events
      log_event = LogEvent.where(loggable: statement, event_type: :closed).last
      expect(log_event.metadata["unrecoverable_notes"]).to contain_exactly("Unrecoverable 1")
    end

    context "when billing_log_events is disabled", feature_setting: { "billing.billing_log_events" => false } do
      it "still creates the statement closed log event" do
        expect { service.log_events }.to change {
          LogEvent.where(loggable: statement, event_type: :closed).count
        }.by(1)
      end
    end
  end
end
