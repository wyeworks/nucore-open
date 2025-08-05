# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::NoticesService do
  let(:order_detail) { OrderDetail.new }
  let(:instance) { described_class.new(order_detail) }

  describe "statuses" do
    subject { instance.notices }

    it "shows nothing for a blank order detail" do
      is_expected.to be_blank
    end

    it "shows nothing for a canceled order detail" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      allow(order_detail).to receive(:canceled?).and_return(true)

      is_expected.to be_blank
    end

    it "shows in review if the order is in review" do
      allow(order_detail).to receive(:in_review?).and_return(true)

      is_expected.to eq([:in_review])
    end

    it "shows in dispute" do
      allow(order_detail).to receive(:in_dispute?).and_return(true)

      is_expected.to eq([:in_dispute])
    end

    it "shows global admin must resolve" do
      allow(order_detail).to receive(:in_dispute?).and_return(true)
      allow(order_detail).to receive(:global_admin_must_resolve?).and_return(true)

      is_expected.to eq([:global_admin_must_resolve])
    end

    it "shows can reconcile" do
      allow(order_detail).to receive(:can_reconcile_journaled?).and_return(true)

      is_expected.to eq([:can_reconcile])
    end

    it "shows ready for journal if setting is on", feature_setting: { ready_for_journal_notice: true } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)

      is_expected.to eq([:ready_for_journal])
    end

    it "shows ready for statement" do
      allow(order_detail).to receive(:ready_for_statement?).and_return(true)

      is_expected.to eq([:ready_for_statement])
    end

    it "does not show ready for journal if setting is off", feature_setting: { ready_for_journal_notice: false } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)

      is_expected.to be_empty
    end

    it "shows in open journal" do
      allow(order_detail).to receive(:in_open_journal?).and_return(true)

      is_expected.to eq([:in_open_journal])
    end

    it "can have multiple notices" do
      allow(order_detail).to receive_messages(
        in_review?: true,
        in_dispute?: true,
      )

      is_expected.to include(:in_review, :in_dispute)
    end
  end

  describe "problems" do
    subject { instance.problems }

    it "shows a problem notice" do
      allow(order_detail).to receive_messages(problem?: true, build_problem_keys: [:missing_price_policy])

      is_expected.to eq([:missing_price_policy])
    end
  end
end
