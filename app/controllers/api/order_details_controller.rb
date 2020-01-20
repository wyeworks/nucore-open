# frozen_string_literal: true

class Api::OrderDetailsController < ApplicationController

  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :order_detail_not_found

  http_basic_authenticate_with(
    name: Rails.application.secrets.api[:basic_auth_name],
    password: Rails.application.secrets.api[:basic_auth_password]
  )

  # Qualtrics requires that we use a query parameter rather than being part of
  # the URL.
  # /api/order_details.json?id=123
  def index
    show
  end

  # /api/order_details/123.json
  def show
    render json: Api::OrderDetail.new(order_detail).to_h
  end

  private

  def order_detail
    @order_detail ||= OrderDetail.find(params[:id])
  end

  def order_detail_not_found
    render json: { error: "not found" }, status: 404
  end

end
