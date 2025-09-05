# frozen_string_literal: true

module OrderDetails

  class Reconciler

    include ActiveModel::Validations

    attr_reader :persist_errors, :count, :order_details, :reconciled_at

    validates :reconciled_at, :order_details, presence: true
    validate :reconciliation_must_be_in_past
    validate :all_journals_and_statements_must_be_before_reconciliation_date

    def initialize(
      order_detail_scope,
      params,
      reconciled_at,
      order_status,
      bulk_reconcile: false,
      **kwargs
    )
      @params = params || ActionController::Parameters.new
      @order_status = order_status || "reconciled"
      @order_details = order_detail_scope.readonly(false).find_ids(to_be_reconciled.keys)
      @reconciled_at = reconciled_at
      @bulk_note = kwargs[:bulk_note] if bulk_reconcile
      @bulk_deposit_number = kwargs[:bulk_deposit_number] if bulk_reconcile
    end

    def reconcile_all
      return 0 unless valid?
      @count = 0
      OrderDetail.transaction do
        order_details.each do |od|
          od_params = @params[od.id.to_s]
          update_status(od, od_params)
        end
      end
      @count
    end

    def full_errors
      Array(persist_errors) + errors.full_messages
    end

    private

    # The params hash comes in with the unchecked IDs as well. Filter out to only
    # those we're going to reconcile. Returns an array of IDs.
    def to_be_reconciled
      @params.select { |_order_detail_id, params| params[:reconciled] == "1" }
    end

    def update_status(order_detail, params)
      order_detail.assign_attributes(allowed(params))

      if @order_status == "reconciled"
        order_detail.reconciled_at = @reconciled_at
        order_detail.reconciled_note = @bulk_note if @bulk_note.present?
        order_detail.deposit_number = @bulk_deposit_number if @bulk_deposit_number.present?
        order_detail.change_status!(OrderStatus.reconciled)
      else
        order_detail.reconciled_at = nil
        order_detail.deposit_number = nil
        order_detail.unrecoverable_note = @bulk_note if @bulk_note.present?
        order_detail.change_status!(OrderStatus.unrecoverable)
      end
      @count += 1
    rescue => e
      @error_fields = { order_detail.id => order_detail.errors.collect { |field, _error| field } }
      @persist_errors = order_detail.errors.full_messages
      @persist_errors = [e.message] if @persist_errors.empty?
      @count = 0
      raise ActiveRecord::Rollback
    end

    def allowed(params)
      params.except(:reconciled).permit(
        :reconciled_note,
        :unrecoverable_note,
        :deposit_number,
      )
    end

    def reconciliation_must_be_in_past
      return unless reconciled_at.present?
      errors.add(:reconciled_at, :must_be_in_past) if reconciled_at > Time.current.end_of_day
    end

    # You cannot set the reconciliation date for a date before the journal/statement date,
    # but we do need to make sure to allow them on the same day.
    def all_journals_and_statements_must_be_before_reconciliation_date
      return unless reconciled_at.present?
      if @order_details.any? { |od| od.journal_or_statement_date&.beginning_of_day&.> reconciled_at }
        errors.add(:reconciled_at, :after_all_journal_dates)
      end
    end

  end

end
