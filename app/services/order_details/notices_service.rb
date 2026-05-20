# frozen_string_literal: true

module OrderDetails
  ##
  # Used to retrieve OrderDetail notices and problems.
  #
  # notices and problems are stored in order detail
  # where as time_based_notices are always computed.
  #
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
    def time_based_notices
      return [] if canceled?

      {
        in_review: in_review?,
        ready_for_statement: ready_for_statement?,
        ready_for_journal: ready_for_journal? && SettingsHelper.feature_on?(:ready_for_journal_notice),
      }.compact_blank.keys
    end

    def problems
      return [] unless complete?

      [
        time_data.problem_description_key,
        (:missing_price_policy if price_policy.blank?),
        (:missing_form if missing_form?),
      ].compact
    end
  end
end
