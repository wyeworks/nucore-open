# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingLogEventPresenter do
  let(:log_event) { LogEvent.new(event_type: event_type, loggable_type: loggable_type, metadata: metadata) }
  let(:event_type) { nil }
  let(:loggable_type) { nil }
  let(:metadata) { {} }

  subject { described_class.new(log_event) }

  describe "#email_to" do
    context "when metadata contains an array of emails" do
      let(:metadata) { { "to" => ["user1@example.com", "user2@example.com"] } }

      it "returns comma-separated emails" do
        expect(subject.email_to).to eq("user1@example.com, user2@example.com")
      end
    end

    context "when metadata contains a single email string" do
      let(:metadata) { { "to" => "single@example.com" } }

      it "returns the email string" do
        expect(subject.email_to).to eq("single@example.com")
      end
    end
  end

  describe "#object" do
    context "for review_orders_email events with order_ids" do
      let(:event_type) { "review_orders_email" }
      let(:metadata) { { "order_ids" => [100, 200, 300], "object" => "Test Account" } }

      it "returns the object from metadata" do
        expect(subject.object).to eq("Test Account")
      end
    end

    context "when metadata has object field" do
      let(:metadata) { { "object" => "Custom Object" } }

      it "returns the object from metadata" do
        expect(subject.object).to eq("Custom Object")
      end
    end
  end

  describe "#order_ids" do
    let(:metadata) { { "order_ids" => [100, 200, 300, 400, 500, 600, 700] } }

    it "returns order IDs from metadata" do
      expect(subject.order_ids).to eq([100, 200, 300, 400, 500, 600, 700])
    end

    it "returns empty array when no order_ids" do
      log_event.metadata.delete("order_ids")
      expect(subject.order_ids).to eq([])
    end
  end

  describe "#has_orders?" do
    let(:metadata) { { "order_ids" => [100, 200, 300] } }

    it "returns true when order_ids present" do
      expect(subject.has_orders?).to be true
    end
  end

  describe "#reconciled_notes" do
    let(:metadata) { { "reconciled_notes" => ["Note 1", "Note 2"] } }

    it "returns reconciled notes from metadata" do
      expect(subject.reconciled_notes).to eq(["Note 1", "Note 2"])
    end
  end

  describe "#unrecoverable_notes" do
    let(:metadata) { { "unrecoverable_notes" => ["Bad note"] } }

    it "returns unrecoverable notes from metadata" do
      expect(subject.unrecoverable_notes).to eq(["Bad note"])
    end
  end

  describe "#all_reconciliation_notes" do
    let(:metadata) do
      {
        "reconciled_notes" => ["Note 1", "Note 2"],
        "unrecoverable_notes" => ["Bad note"]
      }
    end

    it "formats all notes with prefixes" do
      expected_notes = [
        "Reconciled: Note 1",
        "Reconciled: Note 2",
        "Unrecoverable: Bad note"
      ]
      expect(subject.all_reconciliation_notes).to eq(expected_notes)
    end
  end

  describe "#has_reconciliation_data?" do
    let(:event_type) { "closed" }
    let(:loggable_type) { "Statement" }
    let(:metadata) do
      {
        "reconciled_notes" => ["Note 1", "Note 2"],
        "unrecoverable_notes" => ["Bad note"]
      }
    end

    it "returns true with notes" do
      expect(subject.has_reconciliation_data?).to be true
    end

    it "returns false without notes" do
      log_event.metadata.delete("reconciled_notes")
      log_event.metadata.delete("unrecoverable_notes")
      expect(subject.has_reconciliation_data?).to be false
    end
  end
end
