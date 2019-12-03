# frozen_string_literal: true

module SangerSequencing

  class ReceiptSubmissionPresenter

    attr_reader :view_context, :order_detail
    delegate :render, :link_to, to: :view_context

    def initialize(view_context, order_detail)
      @view_context = view_context
      @order_detail = order_detail
    end

    def to_s
      return "" unless submission
      render("sanger_sequencing/purchase_notifier/samples_table", submission: submission, caption: caption)
        .safe_concat(render(body: print_me_text))
    end

    private

    def print_me_text
      I18n.t("views.sanger_sequencing.orders.receipt.print")
    end

    def caption
      text = "#{SangerSequencing::Submission.human_attribute_name(:id)}#{submission.id}"
      submission_path = submission.order_detail.external_service_receiver.show_url

      link_to text, submission_path
    end

    def submission
      return @submission if defined?(@submission)
      @submission = SangerSequencing::Submission.find_by(order_detail_id: order_detail.id)
    end

  end

end
