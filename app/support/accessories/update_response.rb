# frozen_string_literal: true

class Accessories::UpdateResponse
  attr_reader :order_details

  def initialize(order_details)
    @order_details = order_details
  end

  def valid?
    @order_details.all? { |od| od.errors.none? }
  end

  def persisted_count
    @order_details.count(&:persisted?)
  end
end
