# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailNoticePresenter do
  let(:order_detail) { OrderDetail.new(note: "Treat me like a double") }
  let(:presenter) { described_class.new(order_detail) }

  describe "badges_to_html" do
    matcher :have_badge do |expected_text|
      match do |string|
        level = @level || "info"
        html = Nokogiri::HTML(string)
        @element = html.css(".label.label-#{level}").any? { |node| node.text == expected_text }
      end

      chain :with_level do |level|
        @level = level
      end
    end

    it "shows nothing for a blank order detail" do
      expect(presenter.badges_to_html).to be_blank
    end

    it "shows nothing for a canceled order detail" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      allow(order_detail).to receive(:canceled?).and_return(true)
      expect(presenter.badges_to_html).to be_blank
    end

    it "shows in review if the order is in review" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      expect(presenter.badges_to_html).to have_badge("In Review")
    end

    it "shows in dispute" do
      allow(order_detail).to receive(:in_dispute?).and_return(true)
      expect(presenter.badges_to_html).to have_badge("In Dispute")
    end

    it "shows can reconcile" do
      allow(order_detail).to receive(:can_reconcile_journaled?).and_return(true)
      expect(presenter.badges_to_html).to have_badge("Can Reconcile")
    end

    it "shows ready for journal if setting is on", feature_setting: { ready_for_journal_notice: true } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)
      expect(presenter.badges_to_html).to have_badge("Ready for Journal")
    end

    it "does not show ready for journal if setting is off", feature_setting: { ready_for_journal_notice: false } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)
      expect(presenter.badges_to_html).not_to have_badge("Ready for Journal")
    end

    it "shows in open journal" do
      allow(order_detail).to receive(:in_open_journal?).and_return(true)
      expect(presenter.badges_to_html).to have_badge("Open Journal")
    end

    it "shows an important badge for a problem order" do
      allow(order_detail).to receive_messages(problem?: true, problem_description_key: :missing_price_policy)
      expect(presenter.badges_to_html).to have_badge("Missing Price Policy").with_level(:important)
    end

    it "can have multiple badges" do
      # These examples are technically mutually exclusive, but this validates the
      # presenter can handle it.
      allow(order_detail).to receive_messages(
        problem?: true,
        problem_description_key: :missing_price_policy,
        in_review?: true,
        in_dispute?: true,
      )

      html = presenter.badges_to_html
      expect(html).to have_badge("Missing Price Policy").with_level(:important)
      expect(html).to have_badge("In Review")
      expect(html).to have_badge("In Dispute")
    end
  end

  describe "badges_to_text" do
    it "shows nothing for a blank order detail" do
      expect(presenter.badges_to_text).to be_nil
    end

    it "shows nothing for a canceled order detail" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      allow(order_detail).to receive(:canceled?).and_return(true)
      expect(presenter.badges_to_text).to be_nil
    end

    it "shows in review if the order is in review" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      expect(presenter.badges_to_text).to eq("In Review")
    end

    it "shows in dispute" do
      allow(order_detail).to receive(:in_dispute?).and_return(true)
      expect(presenter.badges_to_text).to eq("In Dispute")
    end

    it "shows can reconcile" do
      allow(order_detail).to receive(:can_reconcile_journaled?).and_return(true)
      expect(presenter.badges_to_text).to eq("Can Reconcile")
    end

    it "shows ready for journal if setting is on", feature_setting: { ready_for_journal_notice: true } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)
      expect(presenter.badges_to_text).to eq("Ready for Journal")
    end

    it "does not show ready for journal if setting is off", feature_setting: { ready_for_journal_notice: false } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)
      expect(presenter.badges_to_text).not_to eq("Ready for Journal")
    end

    it "shows in open journal" do
      allow(order_detail).to receive(:in_open_journal?).and_return(true)
      expect(presenter.badges_to_text).to eq("Open Journal")
    end

    it "shows an important badge for a problem order" do
      allow(order_detail).to receive_messages(problem?: true, problem_description_key: :missing_price_policy)
      expect(presenter.badges_to_text).to eq("Missing Price Policy")
    end

    it "can have multiple badges" do
      # These examples are technically mutually exclusive, but this validates the
      # presenter can handle it.
      allow(order_detail).to receive_messages(
        problem?: true,
        problem_description_key: :missing_price_policy,
        in_review?: true,
        in_dispute?: true,
      )

      expect(presenter.badges_to_text).to eq("In Review+In Dispute+Missing Price Policy")
    end
  end

  describe "alerts_to_html" do
    matcher :have_alert do |expected_text|
      match do |string|
        level = @level || "info"
        html = Nokogiri::HTML(string)
        html.at_css(".alert.alert-#{level}").text.match(expected_text)
      end

      chain :with_level do |level|
        @level = level
      end
    end

    it "shows nothing with no warnings/info" do
      expect(presenter.alerts_to_html).to be_blank
    end

    it "shows nothing for a canceled order detail" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      allow(order_detail).to receive(:canceled?).and_return(true)
      expect(presenter.alerts_to_html).to be_blank
    end

    it "shows in review if the order is in review" do
      allow(order_detail).to receive(:in_review?).and_return(true)
      expect(presenter.alerts_to_html).to have_alert(/in review/)
    end

    it "shows in dispute" do
      allow(order_detail).to receive(:in_dispute?).and_return(true)
      expect(presenter.alerts_to_html).to have_alert(/Resolve Dispute/)
    end

    it "shows can reconcile" do
      allow(order_detail).to receive(:can_reconcile_journaled?).and_return(true)
      expect(presenter.alerts_to_html).to have_alert(/can be reconciled/)
    end

    it "shows in open journal" do
      allow(order_detail).to receive(:in_open_journal?).and_return(true)
      expect(presenter.alerts_to_html).to have_alert(/pending journal/)
    end

    it "shows ready for journal if setting is on", feature_setting: { ready_for_journal_notice: true } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(true)
      expect(presenter.alerts_to_html).to have_alert(/ready to be journaled/)
    end

    it "does not show ready for journal if setting is off", feature_setting: { ready_for_journal_notice: false } do
      allow(order_detail).to receive(:ready_for_journal?).and_return(false)
      expect(presenter.alerts_to_html).to be_empty
    end

    it "shows an important badge for a problem order" do
      allow(order_detail).to receive_messages(problem?: true, problem_description_key: :missing_price_policy)
      expect(presenter.alerts_to_html).to have_alert(/does not have a price policy/).with_level(:error)
    end

    it "can have multiple badges" do
      # These examples are technically mutually exclusive, but this validates the
      # presenter can handle it.
      allow(order_detail).to receive_messages(
        problem?: true,
        problem_description_key: :missing_price_policy,
        in_review?: true,
        in_dispute?: true,
      )

      html = presenter.alerts_to_html
      expect(html).to have_alert(/does not have a price policy/).with_level(:error)
      expect(html).to have_alert(/in review/)
      expect(html).to have_alert(/resolve dispute/i)
    end
  end

end
