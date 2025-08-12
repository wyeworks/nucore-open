# frozen_string_literal: true

require "rails_helper"

RSpec.describe BillingLogEventPresenter do
  let(:statement) { build_stubbed(:statement, id: 456, account_id: 123) }
  let(:journal) { build_stubbed(:journal, id: 789) }
  let(:user) { build_stubbed(:user, email: "test@example.com") }

  describe "#email_to" do
    subject { described_class.new(log_event) }

    context "when metadata contains an array of emails" do
      let(:log_event) { LogEvent.new(metadata: { "to" => ["user1@example.com", "user2@example.com"] }) }

      it "returns comma-separated emails" do
        expect(subject.email_to).to eq("user1@example.com, user2@example.com")
      end
    end

    context "when metadata contains a single email string" do
      let(:log_event) { LogEvent.new(metadata: { "to" => "single@example.com" }) }

      it "returns the email string" do
        expect(subject.email_to).to eq("single@example.com")
      end
    end
  end

  describe "#object" do
    context "for review_orders_email events with order_ids" do
      let(:log_event) do
        LogEvent.new(
          event_type: "review_orders_email",
          metadata: { "order_ids" => [100, 200, 300] }
        )
      end
      subject { described_class.new(log_event) }

      it "includes order numbers in the object description" do
        expect(subject.object).to include("Orders: 100, 200, 300")
      end
    end

    context "when metadata has object field" do
      let(:log_event) { LogEvent.new(metadata: { "object" => "Custom Object" }) }
      subject { described_class.new(log_event) }

      it "returns the object from metadata" do
        expect(subject.object).to eq("Custom Object")
      end
    end
  end

  describe "order-related methods" do
    let(:log_event) { LogEvent.new(metadata: { "order_ids" => [100, 200, 300, 400, 500, 600, 700] }) }
    subject { described_class.new(log_event) }

    describe "#order_ids_display" do
      it "shows first 5 and indicates more when over 5" do
        expect(subject.order_ids_display).to eq("100, 200, 300, 400, 500, and 2 more")
      end

      it "shows all when 5 or fewer" do
        log_event.metadata["order_ids"] = [100, 200, 300]
        expect(subject.order_ids_display).to eq("100, 200, 300")
      end
    end

    it "has_orders? returns true when order_ids present" do
      expect(subject.has_orders?).to be true
    end
  end

  describe "reconciliation methods" do
    let(:log_event) do
      LogEvent.new(
        event_type: "closed",
        loggable_type: "Statement",
        metadata: {
          "reconciled_notes" => ["Note 1", "Note 2"],
          "unrecoverable_notes" => ["Bad note"]
        }
      )
    end
    subject { described_class.new(log_event) }

    it "returns reconciled notes from metadata" do
      expect(subject.reconciled_notes).to eq(["Note 1", "Note 2"])
    end

    it "returns unrecoverable notes from metadata" do
      expect(subject.unrecoverable_notes).to eq(["Bad note"])
    end

    it "formats all notes with prefixes" do
      expected = [
        "Reconciled: Note 1",
        "Reconciled: Note 2",
        "Unrecoverable: Bad note"
      ]
      expect(subject.all_reconciliation_notes).to eq(expected)
    end

    describe "#has_reconciliation_data?" do
      it "returns true with notes" do
        expect(subject.has_reconciliation_data?).to be true
      end

      it "returns false for non-statement events" do
        log_event.loggable_type = "Journal"
        expect(subject.has_reconciliation_data?).to be false
      end
    end
  end
end