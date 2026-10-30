# frozen_string_literal: true

module OrderDetails
  class Reconciler
    include ActiveModel::Validations

    attr_reader :persist_errors, :count, :order_details, :reconciled_at

    validates :reconciled_at, presence: true, if: :reconciling?
    validate :reconciliation_must_be_in_past, if: -> { reconciled_at.present? && reconciling? }
    validate :all_journals_and_statements_must_be_before_reconciliation_date, if: -> { reconciled_at.present? && reconciling? }

    def initialize(
      order_details:,
      reconciled_at:,
      order_status: nil,
      order_detail_attributes: {},
      bulk_reconcile: false,
      **kwargs
    )
      @order_status = order_status || "reconciled"
      @order_details = writable(order_details)
      @order_detail_attributes = (order_detail_attributes || {}).to_h.transform_keys(&:to_i)
      @reconciled_at = reconciled_at
      @bulk_note = kwargs[:bulk_note] if bulk_reconcile
      @bulk_deposit_number = kwargs[:bulk_deposit_number] if bulk_reconcile
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

          attributes = @order_detail_attributes.fetch(order_detail.id, {})
          begin
            update_status(order_detail, attributes)
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
          order_detail.deposit_number = nil
          order_detail.reconciled_note = nil
          order_detail.unreconcile!
          @count += 1
        rescue AASM::InvalidTransition, ActiveRecord::RecordInvalid => e
          @persist_errors << "Order ##{order_detail.id}: #{e.message}"
        end
      end

      @count
    end

    def full_errors
      Array(persist_errors) + errors.full_messages
    end

    private

    def writable(order_details)
      order_details.respond_to?(:readonly) ? order_details.readonly(false) : order_details
    end

    def reconciling?
      @order_status == "reconciled"
    end

    def update_status(order_detail, attributes)
      order_detail.assign_attributes(attributes)

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

    def reconciliation_must_be_in_past
      return unless reconciled_at.present?

      errors.add(:reconciled_at, :must_be_in_past) if reconciled_at > Time.current.end_of_day
    end

    def all_journals_and_statements_must_be_before_reconciliation_date
      return if reconciled_at.blank? || @order_details.blank?

      if @order_details.any? { |od| od.journal_or_statement_date.beginning_of_day > reconciled_at }
        errors.add(:reconciled_at, :after_all_journal_dates)
      end
    end
  end
end
