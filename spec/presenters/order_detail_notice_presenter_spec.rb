# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailNoticePresenter do
  let(:order_detail) { OrderDetail.new(note: "Treat me like a double") }
  let(:presenter) { described_class.new(order_detail) }

  describe "badges_to_html" do
    matcher :have_html_badge do |expected_text|
      match do |string|
        level_class = case @level
                      when :important
                        "danger"
                      else
                        @level || "info"
                      end
        html = Nokogiri::HTML(string)
        @element = html.css(".label.label-#{level_class}").any? { |node| node.text == expected_text }
      end

      chain :with_level do |level|
        @level = level
      end
    end

    it "shows nothing for a blank order detail" do
      expect(presenter.badges_to_html).to be_blank
    end

    it "shows in review if the order is in review" do
      order_detail.notice_keys << :in_review

      expect(presenter.badges_to_html).to have_html_badge("In Review")
      expect(presenter.badges_to_text).to eq("In Review")
    end

    it "shows in dispute" do
      order_detail.notice_keys << :in_dispute

      expect(presenter.badges_to_html).to have_html_badge("In Dispute")
      expect(presenter.badges_to_text).to eq("In Dispute")
    end

    it "shows in dispute resolvable by admin" do
      order_detail.notice_keys << :global_admin_must_resolve

      expect(presenter.badges_to_html).to have_html_badge("In Dispute (Admin)")
      expect(presenter.badges_to_text).to eq("In Dispute (Admin)")
    end

    it "shows can reconcile" do
      order_detail.notice_keys << :can_reconcile

      expect(presenter.badges_to_html).to have_html_badge("Can Reconcile")
      expect(presenter.badges_to_text).to eq("Can Reconcile")
    end

    it "shows ready for journal if setting is on" do
      order_detail.notice_keys << :ready_for_journal

      expect(presenter.badges_to_html).to have_html_badge("Ready for Journal")
      expect(presenter.badges_to_text).to eq("Ready for Journal")
    end

    it "shows ready for statement" do
      order_detail.notice_keys << :ready_for_statement

      expect(presenter.badges_to_html).to have_html_badge("Ready for #{I18n.t('Statement')}")
      expect(presenter.badges_to_text).to eq("Ready for #{I18n.t('Statement')}")
    end

    it "shows in open journal" do
      order_detail.notice_keys << :in_open_journal

      expect(presenter.badges_to_html).to have_html_badge("Open Journal")
      expect(presenter.badges_to_text).to eq("Open Journal")
    end

    it "shows an important badge for a problem order" do
      allow(order_detail).to(
        receive_messages(
          problem?: true,
          problem_description_key: :missing_price_policy,
        )
      )

      expect(presenter.badges_to_html).to(
        have_html_badge("Missing Price Policy").with_level(:important)
      )
      expect(presenter.badges_to_text).to eq("Missing Price Policy")
    end

    it "detects problem flag without problem description" do
      allow(order_detail).to(
        receive_messages(problem?: true, problem_description_key: nil)
      )

      expect(presenter.badges_to_html).to(
        have_html_badge("Problem out of sync").with_level(:important)
      )
      expect(presenter.badges_to_text).to eq("Problem out of sync")
    end

    it "can have multiple badges" do
      # These examples are technically mutually exclusive, but this validates the
      # presenter can handle it.
      allow(order_detail).to receive_messages(
        problem?: true,
        problem_description_key: :missing_price_policy,
      )
      order_detail.notice_keys = %i[
        in_review
        in_dispute
      ]

      html = presenter.badges_to_html
      expect(html).to have_html_badge("Missing Price Policy").with_level(:important)
      expect(html).to have_html_badge("In Review")
      expect(html).to have_html_badge("In Dispute")

      text = presenter.badges_to_text
      expect(text).to include("Missing Price Policy")
      expect(text).to include("In Review")
      expect(text).to include("In Dispute")
    end
  end

end
