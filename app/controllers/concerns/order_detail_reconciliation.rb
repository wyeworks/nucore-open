# frozen_string_literal: true

module OrderDetailReconciliation
  extend ActiveSupport::Concern

  private

  def reconciliation_params
    return ActionController::Parameters.new unless params[:order_detail].is_a?(ActionController::Parameters)

    params[:order_detail]
  end

  def selected_order_detail_ids
    reconciliation_params.select { |_id, attributes| attributes[:selected] == "1" }.keys
  end

  def permitted_order_detail_attributes
    [:reconciled_note, :unrecoverable_note, :deposit_number]
  end

  def order_detail_attributes
    reconciliation_params
      .permit(selected_order_detail_ids.index_with { permitted_order_detail_attributes })
      .to_h
  end
end
