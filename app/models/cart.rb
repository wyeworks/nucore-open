# frozen_string_literal: true

class Cart

  def initialize(user, created_by_user = nil)
    @user = user
    @created_by_user = created_by_user || @user
  end

  def order
    non_reservation_only_cart || new_cart
  end

  def new_cart
    Order.create(user: @user,
                 created_by: @created_by_user.id)
  end

  def self.destroy_all_instrument_only_carts(before = Time.zone.now)
    count = 0
    total = Cart.abandoned_carts.count
    # limit to 100 for better ability to watch progress
    while (cart = abandoned_carts(100).where("orders.updated_at < ?", before)).any?
      destroyed = cart.destroy_all
      Rails.logger.info "Removed #{count += destroyed.count} of #{total} carts"
    end
  end

  def self.abandoned_carts(limit = nil)
    # Orders with one order detail
    subquery = OrderDetail.joins(:order)
                          .merge(Order.carts)
                          .group(:order_id)
                          .having("count(*) = 1")
                          .select(:order_id)

    orders = Order.joins(order_details: :product)
                  .where(products: { type: "Instrument" })
                  .where(id: subquery)

    orders = orders.limit(limit) if limit
    orders.readonly(false)
  end

  private

  # Will find the first cart that either has a non-instrument,
  # has multiple items, or is empty
  def non_reservation_only_cart
    all_carts.find { |order| order.order_details.item_and_service_orders.any? || order.order_details.size != 1 }
  end

  def all_carts
    @user.orders
         .created_by_user(@created_by_user)
         .carts.order(updated_at: :desc)
  end

end
