# frozen_string_literal: true

class InstrumentIssuesController < ApplicationController

  customer_tab :all
  before_action :init_current_facility
  before_action :init_order_detail
  before_action :init_product
  before_action :init_instrument_issue, only: %i[new create]
  layout -> { modal? ? false : "application" }

  def new
    @redirect_to_order_id = params[:redirect_to_order_id]
    @modal_view = @redirect_to_order_id.present?
  end

  def create
    @instrument_issue.assign_attributes(create_params)

    if @instrument_issue.send_notification
      redirect_to redirect_to_path, notice: text("create.success")
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:instrument_issue).permit(:message)
  end

  def init_order_detail
    @order_detail = OrderDetail.find(params[:order_detail_id])
  end

  def init_product
    @product = @order_detail.product
  end

  def init_instrument_issue
    @instrument_issue = InstrumentIssue.new(product: @product,
                                            user: current_user,
                                            order_detail: @order_detail)
  end

  def redirect_to_path
    redirect_to_order_id = params[:redirect_to_order_id]

    # This means the request came from a modal on the order show page
    if redirect_to_order_id.present?
      order = Order.find(redirect_to_order_id)

      if order.present?
        facility_order_path(order.facility, order)
      else
        # We shouldn't get here, so this is here just so the user is redirected somewhere
        reservations_path
      end
    else
      reservations_path
    end
  end

  def modal?
    request.xhr?
  end
  helper_method :modal?
end
