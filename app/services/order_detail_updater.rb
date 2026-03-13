# frozen_string_literal: true

class OrderDetailUpdater

  attr_reader :order, :params, :quantities_changed
  alias quantities_changed? quantities_changed

  def initialize(order, params)
    @order = order
    @params = params
    @initial_quantities = quantities
  end

  def update
    order.save
    update_result = order.update_details(params)
    @quantities_changed = (@initial_quantities != quantities)
    update_result
  end

  def update!
    update || raise(NUCore::OrderDetailUpdateException)
  end

  private

  def quantities
    order.order_details.order("order_details.id").pluck(:quantity)
  end

end
