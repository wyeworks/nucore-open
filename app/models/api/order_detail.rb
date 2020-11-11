# frozen_string_literal: true

class Api::OrderDetail

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def to_h
    {
      order_number: @order_detail.order_number,
      account: account_to_hash,
      ordered_for: ordered_for_to_hash,
    }
  end

  private

  def account
    @account ||= @order_detail.account
  end

  def account_to_hash
    if account.present?
      { id: account.id, owner: user_to_hash(account.owner_user) }
    end
  end

  def ordered_for_to_hash
    user_to_hash(@order_detail.order.user)
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
