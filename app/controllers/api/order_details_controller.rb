class Api::OrderDetailsController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :order_detail_not_found

  http_basic_authenticate_with name: Settings.api.basic_auth_name, password: Settings.api.basic_auth_password

  def show
    render json: response_to_hash
  end

  private

  def account
    @account = order_detail.try(:account) unless defined?(@account)
    @account
  end

  def account_to_hash
    if account.present?
      { id: account.id, owner: user_to_hash(account.owner.user) }
    end
  end

  def ordered_for_to_hash
    if order_detail.present?
      user_to_hash(order_detail.order.user)
    end
  end

  def response_to_hash
    { account: account_to_hash, ordered_for: ordered_for_to_hash }
  end

  def order_detail
    @order_detail ||= OrderDetail.find(params[:id])
  end

  def order_detail_not_found
    respond_to do |format|
      format.json { render text: { error: "not found" }.to_json, status: 404 }
    end
  end

  def user_to_hash(user)
    {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
    }
  end
end
