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

      @order_details = []
      if @params.present? && !@params.empty?
        selected_ids = @params.select { |_, p| p[:selected] == "1" }.keys
        if selected_ids.any?
          @order_details = @order_detail_scope.where(id: selected_ids)
        end
      end
    end

    def reconcile_all
      return 0 unless valid?
      @count = 0
      @persist_errors = []

      OrderDetail.transaction do
        order_details.each do |od|
          next if @order_status == "reconciled" && od.reconciled?
          next if @order_status == "unrecoverable" && od.unrecoverable?

          od_params = @params[od.id.to_s] || {}
          begin
            od.assign_attributes(allowed(od_params))

            if @order_status == "reconciled"
              od.reconciled_at = @reconciled_at
              od.reconciled_note = @bulk_note if @bulk_note.present?
              od.deposit_number = @bulk_deposit_number if @bulk_deposit_number.present?
              od.change_status!(OrderStatus.reconciled)
            else # unrecoverable
              od.reconciled_at = nil
              od.deposit_number = nil
              od.unrecoverable_note = @bulk_note if @bulk_note.present?
              od.change_status!(OrderStatus.unrecoverable)
            end

            @count += 1
          rescue => e
            @persist_errors << "Order ##{od.id}: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end
      end
      @count
    end

    def unreconcile_all
      @count = 0
      @persist_errors = []

      OrderDetail.transaction do
        order_details.each do |od|
          next unless od.reconciled?

          begin
            od.update!(
              state: "complete",
              order_status: OrderStatus.complete,
              reconciled_at: nil,
              deposit_number: nil
            )
            @count += 1
          rescue => e
            @persist_errors << "Order ##{od.id}: #{e.message}"
          end
        end
      end
      @count
    end

    def full_errors
      Array(persist_errors) + errors.full_messages
    end

    private

    def reconciling?
      @order_status == "reconciled"
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
      if @order_details.any? { |od| od.journal_or_statement_date&.beginning_of_day&.> reconciled_at }
        errors.add(:reconciled_at, :after_all_journal_dates)
      end
    end

  end

end
