# frozen_string_literal: true

module UmassCorum

  # Handles form input for marking completed VoucherSplitAccount orders MIVP Pending:
  # The user has paid but Mass Innovation Voucher Program (MIVP) reimbursement is still pending.
  # Customized from OrderDetails::Reconciler
  class VoucherReconciler

    include ActiveModel::Validations

    attr_reader :persist_errors, :count, :order_details

    validates :order_details, presence: true

    def initialize(order_detail_scope, params, bulk_reconcile_note = nil)
      @params = params || ActionController::Parameters.new
      @order_details = order_detail_scope.readonly(false).find_ids(to_be_updated.keys)
      @bulk_reconcile_note = bulk_reconcile_note
    end

    def reconcile_all
      return 0 unless valid?

      @count = 0
      OrderDetail.transaction do
        order_details.each do |od|
          od_params = @params[od.id.to_s]
          mivp_pending(od, od_params)
        end
      end
      @count
    end

    def full_errors
      Array(persist_errors) + errors.map { |_attr, msg| msg }
    end

    private

    # The params hash comes in with the unchecked IDs as well. Filter out to only
    # those we're going to mark mivp_pending. Returns an array of IDs.
    def to_be_updated
      @params.select { |_order_detail_id, params| params[:mivp_pending] == "1" }
    end

    def mivp_pending(order_detail, params)
      order_detail.assign_attributes(allowed(params))
      order_detail.reconciled_note = @bulk_reconcile_note if @bulk_reconcile_note
      order_detail.change_status!(VoucherOrderStatus.mivp)
      @count += 1
    rescue => e
      @error_fields = { order_detail.id => order_detail.errors.collect { |field, _error| field } }
      @persist_errors = order_detail.errors.full_messages
      @persist_errors = [e.message] if @persist_errors.empty?
      @count = 0
      raise ActiveRecord::Rollback
    end

    def allowed(params)
      params.except(:reconciled).permit(:reconciled_note)
    end

  end

end
