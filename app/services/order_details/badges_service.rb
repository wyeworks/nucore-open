# frozen_string_literal: true

module OrderDetails
  class BadgesService
    attr_reader :order_detail

    delegate_missing_to :order_detail

    def initialize(order_detail)
      @order_detail = order_detail
    end

    def statuses
      return [] if canceled?

      statuses = []

      statuses << :in_review if in_review?
      statuses << :in_dispute if in_dispute? && !global_admin_must_resolve?
      statuses << :global_admin_must_resolve if in_dispute? && global_admin_must_resolve?
      statuses << :missing_form if missing_form? && !problem?
      statuses << :can_reconcile if can_reconcile_journaled?
      statuses << :in_open_journal if in_open_journal?
      statuses << :ready_for_statement if ready_for_statement?
      statuses << :ready_for_journal if ready_for_journal? && SettingsHelper.feature_on?(:ready_for_journal_notice)
      statuses << :awaiting_payment if awaiting_payment?

      statuses
    end
  end
end
