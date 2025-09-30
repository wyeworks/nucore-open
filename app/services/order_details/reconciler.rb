# frozen_string_literal: true

module OrderDetails

  class Reconciler

    include ActiveModel::Validations

    attr_reader :persist_errors, :count, :order_details, :reconciled_at

    validates :reconciled_at, presence: true, if: :reconciling?
    validate :reconciliation_must_be_in_past, if: -> { reconciled_at.present? && reconciling? }
    validate :all_journals_and_statements_must_be_before_reconciliation_date, if: -> { reconciled_at.present? && reconciling? }

    def initialize(
      order_detail_scope,
      params,
      reconciled_at,
      order_status = nil,
      bulk_reconcile: false,
      **kwargs
    )
      @params = params || ActionController::Parameters.new
      @order_status = order_status || "reconciled"
      @order_detail_scope = order_detail_scope.readonly(false)
      @reconciled_at = reconciled_at
      @bulk_note = kwargs[:bulk_note] if bulk_reconcile
      @bulk_deposit_number = kwargs[:bulk_deposit_number] if bulk_reconcile
      @order_details = load_selected_order_details
    end

    def reconcile_all
      return 0 unless valid?
      @count = 0
      @persist_errors = []
      rollback_occurred = false

      OrderDetail.transaction do
        order_details.each do |order_detail|
          next if @order_status == "reconciled" && order_detail.reconciled?
          next if @order_status == "unrecoverable" && order_detail.unrecoverable?

          params = @params[order_detail.id.to_s] || {}
          begin
            update_status(order_detail, params)
            @count += 1
          rescue => e
            @persist_errors << "Order ##{order_detail.id}: #{e.message}"
            rollback_occurred = true
            raise ActiveRecord::Rollback
          end
        end
      end

      rollback_occurred ? 0 : @count
    end

    def unreconcile_all
      @count = 0
      @persist_errors = []

      order_details.each do |order_detail|
        next unless order_detail.reconciled?

        begin
          order_detail.update_columns(
            state: "complete",
            order_status_id: OrderStatus.complete.id,
            reconciled_at: nil,
            deposit_number: nil,
            reconciled_note: nil,
            updated_at: Time.current
          )
          @count += 1
        rescue => e
          @persist_errors << "Order ##{order_detail.id}: #{e.message}"
        end
      end

      @count
    end

    def full_errors
      Array(persist_errors) + errors.full_messages
    end

    private

    def load_selected_order_details
      return [] if @params.blank?

      selected_ids = @params.select { |_, p| p[:selected] == "1" }.keys

      @order_detail_scope.where(id: selected_ids)
    end

    def reconciling?
      @order_status == "reconciled"
    end

    def update_status(order_detail, params)
      order_detail.assign_attributes(allowed(params))

      if @order_status == "reconciled"
        order_detail.reconciled_at = @reconciled_at
        order_detail.reconciled_note = @bulk_note if @bulk_note.present?
        order_detail.deposit_number = @bulk_deposit_number if @bulk_deposit_number.present?
        order_detail.change_status!(OrderStatus.reconciled)
      else # unrecoverable
        order_detail.reconciled_at = nil
        order_detail.deposit_number = nil
        order_detail.unrecoverable_note = @bulk_note if @bulk_note.present?
        order_detail.change_status!(OrderStatus.unrecoverable)
      end
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

    def all_journals_and_statements_must_be_before_reconciliation_date
      return unless reconciled_at.present? && @order_details.present?
      if @order_details.any? { |od| od.journal_or_statement_date.beginning_of_day > reconciled_at }
        errors.add(:reconciled_at, :after_all_journal_dates)
      end
    end

  end

end
