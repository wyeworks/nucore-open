# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journals::Closer do
  let(:facility) { create(:facility) }
  let(:journal) do
    create(
      :journal,
      :with_completed_order,
      facility:,
      is_successful: nil,
    )
  end
  let(:params) do
    ActionController::Parameters.new(
      reference: "#123",
      description: "Journal closed",
      updated_by: create(:user, :administrator).id,
    )
  end
  subject { described_class.new(journal, params) }

  shared_examples "closing journal" do |status, is_successful|
    it "closes without errors" do
      expect(subject.perform(status)).to be true
    end

    it "sets the journal state" do
      expect { subject.perform(status) }.to(
        change do
          journal.is_successful
        end.from(nil).to(is_successful)
      )
    end

    it "enqueues order detail notice updates" do
      expect { subject.perform(status) }.to(
        have_enqueued_job(OrderDetailNoticesUpdateJob).exactly(
          journal.order_details.count
        )
      )
    end
  end

  describe "failed" do
    it_behaves_like "closing journal", "failed", false
  end

  describe "succeeded_errors" do
    it_behaves_like "closing journal", "succeeded_errors", true
  end

  describe "succeeded" do
    it_behaves_like "closing journal", "succeeded", true
  end

  describe "close errors" do
    let(:params) { ActionController::Parameters.new }

    it "does not schedule update order notices on error" do
      expect { subject.perform("succeeded") }.not_to have_enqueued_job
    end
  end
end
