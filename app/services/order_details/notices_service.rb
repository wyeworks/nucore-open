# frozen_string_literal: true

module OrderDetails
  class NoticesService
    attr_reader :order_detail

    delegate_missing_to :order_detail

    def initialize(order_detail)
      @order_detail = order_detail
    end

    def notices
      return [] if canceled?

      statuses = []

      statuses << :in_review if in_review?
      # account
      statuses << :in_dispute if in_dispute? && !global_admin_must_resolve?
      statuses << :global_admin_must_resolve if in_dispute? && global_admin_must_resolve?
      # product.stored_files.template
      # product.external_service_passers.active (product.active_survey?)
      statuses << :missing_form if missing_form? && !problem?
      # account
      # journal (account.can_reconcile?(self))
      # can call missing_form? when ready_for_journal? is checked
      statuses << :can_reconcile if can_reconcile_journaled?
      # journal
      statuses << :in_open_journal if in_open_journal?
      # calls missing_form?
      statuses << :ready_for_statement if ready_for_statement?
      # calls missing_form?
      statuses << :ready_for_journal if ready_for_journal? && SettingsHelper.feature_on?(:ready_for_journal_notice)
      statuses << :awaiting_payment if awaiting_payment?

      statuses
    end

    def problems
      build_problem_keys
    end
  end
end
