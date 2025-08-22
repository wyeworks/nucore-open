# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconciliationLogService do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:statement) { create(:statement, facility: facility) }
  let(:order_status_reconciled) { OrderStatus.find_or_create_by(name: "Reconciled") }
  let(:order_status_unrecoverable) { OrderStatus.find_or_create_by(name: "Unrecoverable") }
  
  let(:order_details) do
    [
      create(:order_detail, statement: statement, order_status: order_status_reconciled, reconciled_note: "Note 1"),
      create(:order_detail, statement: statement, order_status: order_status_reconciled, reconciled_note: "Note 2"),
      create(:order_detail, statement: statement, order_status: order_status_unrecoverable, unrecoverable_note: "Unrecoverable 1"),
    ]
  end

  let(:service) { described_class.new(order_details, user) }

  describe "#log_events" do
    context "when billing_log_events is enabled", feature_setting: { billing_log_events: true } do
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
    end

    context "when billing_log_events is disabled", feature_setting: { billing_log_events: false } do
      it "does not create a log event" do
        expect { service.log_events }.not_to change {
          LogEvent.where(loggable: statement, event_type: :closed).count
        }
      end
    end
  end
end