# frozen_string_literal: true

class ReconcilliationsController < ApplicationController
  load_resource :order
  load_resource :order_detail, through: :order

  def destroy
    authorize! :unreconcile, @order_detail

    @order_detail.unreconcile! if @order_detail.reconciled?
    redirect_to facility_transactions_path(current_facility)
  end
end
