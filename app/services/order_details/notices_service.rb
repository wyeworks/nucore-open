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

      {
        in_dispute: in_dispute? && !global_admin_must_resolve?,
        global_admin_must_resolve: in_dispute? && global_admin_must_resolve?,
        missing_form: missing_form? && !problem?,
        can_reconcile: can_reconcile_journaled?,
        in_open_journal: in_open_journal?,
        awaiting_payment: awaiting_payment?,
      }.compact_blank.keys
    end

    ##
    # Notices that cannot be stored since depend on current time
    def dynamic_notices
      return [] if canceled?

      {
        in_review: in_review?,
        ready_for_statement: ready_for_statement?,
        ready_for_journal: ready_for_journal? && SettingsHelper.feature_on?(:ready_for_journal_notice),
      }.compact_blank.keys
    end

    def problems
      build_problem_keys
    end
  end
end
