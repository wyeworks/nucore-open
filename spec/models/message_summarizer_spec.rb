# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageSummarizer do
  subject { MessageSummarizer.new(controller) }
  let(:admin_tab?) { false }
  let(:controller) { FacilitiesController.new }
  let(:current_facility) { facility }
  let(:facility) { order.facility }
  let(:order) { create(:purchased_order, product: product) }
  let(:order_detail) { order.order_details.first }
  let(:product) { create(:instrument_requiring_approval) }
  let(:user) { create(:user) }

  before(:each) do
    allow(controller).to receive(:admin_tab?).and_return(admin_tab?)
    allow(controller).to receive(:current_facility).and_return(current_facility)
    allow(controller).to receive(:current_user).and_return(user)

    subject.summaries.each do |summary|
      allow(summary).to receive(:path).and_return("/stub")
    end
  end

  def create_merge_notification
    merge_to_order = order.dup
    merge_to_order.save!
    order.update_attribute(:merge_with_order_id, merge_to_order.id)
    MergeNotification.create_for!(user, order_detail.reload)
  end

  def set_problem_order
    order_detail.update_attribute(:state, :complete)
    order_detail.set_problem_and_notices
  end

  shared_examples_for "there are no messages" do
    it "has no messages of any kind" do
      expect(subject).not_to be_messages
      expect(subject.count).to eq(0)

      iteration_count = 0
      subject.each { ++iteration_count }
      expect(iteration_count).to eq(0)
    end
  end

  shared_examples_for "there is one overall message" do
    it "has one message" do
      expect(subject).to be_messages
      expect(subject.count).to eq(1)

      summaries = []

      subject.each do |message_summary|
        summaries << message_summary
        expect(message_summary).to be_any
        expect(message_summary.count).to eq(1)
      end

      expect(summaries.count).to eq(1)
    end
  end

  shared_examples_for "it has a visible notices tab" do |count|
    it { expect(subject).to be_visible_tab }
    it { expect(subject.tab_label).to eq("Notices (#{count})") }
  end

  shared_examples_for "the notices tab is not visible" do
    it { expect(subject).not_to be_visible_tab }
  end

  context "when no active notifications, training requests, disputed or problem orders exist" do
    it_behaves_like "there are no messages"

    context "when not in a manager context" do
      it_behaves_like "the notices tab is not visible"
    end

    context "when in a manager context" do
      let(:admin_tab?) { true }
      let(:user) { create :user, :administrator }

      it_behaves_like "it has a visible notices tab", 0
    end
  end

  context "when an active notification exists" do
    before { create_merge_notification }

    context "and the user may view notifications" do
      it_behaves_like "there is one overall message"

      context "when not in a manager context" do
        it_behaves_like "there is one overall message"
        it_behaves_like "it has a visible notices tab", 1
        it { expect(subject.first.link).to match(/\bNotices \(1\)/) }
      end

      context "when in a manager context" do
        let(:admin_tab?) { true }

        it_behaves_like "there is one overall message"
        it_behaves_like "it has a visible notices tab", 1
        it { expect(subject.first.link).to match(/\bNotices \(1\)/) }
      end
    end
  end

  context "when a disputed order detail exists" do
    before { order_detail.update_attribute(:dispute_at, 1.day.ago) }

    context "and the user can access disputed order details" do
      let(:user) { create(:user, :facility_director, facility: facility) }

      context "when in a manager context" do
        let(:admin_tab?) { true }

        it_behaves_like "there is one overall message"
        it_behaves_like "it has a visible notices tab", 1

        it { expect(subject.first.link).to match(/\bDisputed Orders \(1\)/) }
      end

      context "when not in a manager context" do
        it_behaves_like "the notices tab is not visible"
      end
    end

    context "and the user cannot access disputed order details" do
      it_behaves_like "the notices tab is not visible"
    end
  end

  context "when a problem order detail exists" do
    let(:product) { create(:setup_item) }

    before(:each) { set_problem_order }

    context "and the user can access problem orders" do
      let(:user) { create(:user, :facility_director, facility: facility) }

      context "when in a manager context" do
        let(:admin_tab?) { true }

        it_behaves_like "there is one overall message"
        it_behaves_like "it has a visible notices tab", 1
        it { expect(subject.first.link).to match(/\bProblem Orders \(1\)/) }
      end

      context "when not in a manager context" do
        it_behaves_like "the notices tab is not visible"
      end
    end

    context "and the user cannot access problem orders" do
      let(:user) { create(:user, :staff, facility: facility) }
      it_behaves_like "the notices tab is not visible"
    end
  end

  context "when a problem reservation order detail exists" do
    before(:each) { set_problem_order }

    context "and the user can access problem reservations" do
      let(:user) { create(:user, :facility_director, facility: facility) }

      context "when in a manager context" do
        let(:admin_tab?) { true }

        it_behaves_like "there is one overall message"
        it_behaves_like "it has a visible notices tab", 1
        it { expect(subject.first.link).to match(/\bProblem Reservations \(1\)/) }
      end

      context "when not in a manager context" do
        it_behaves_like "the notices tab is not visible"
      end
    end

    context "and the user cannot access problem reservations" do
      let(:user) { create(:user, :staff, facility: facility) }
      it_behaves_like "the notices tab is not visible"
    end
  end

  context "when a training request exists" do
    before { create(:training_request, product: product) }

    context "and the user can manage training requests" do
      let(:user) { create(:user, :staff, facility: facility) }

      context "when in a manager context" do
        let(:admin_tab?) { true }

        context "and the training request feature is enabled", feature_setting: { training_requests: true } do
          it_behaves_like "there is one overall message"
          it_behaves_like "it has a visible notices tab", 1

          it { expect(subject.first.link).to match(/\bTraining Requests \(1\)/) }
        end

        context "and the training request feature is disabled", feature_setting: { training_requests: false } do
          it_behaves_like "it has a visible notices tab", 0
        end
      end

      context "when not in a manager context" do
        it_behaves_like "the notices tab is not visible"
      end
    end

    context "and the user cannot manage training requests" do
      it_behaves_like "the notices tab is not visible"
    end
  end
end
