# frozen_string_literal: true

module Accessories::Scaling
  def self.decorate(order_detail)
    case order_detail.product_accessory.try :scaling_type
    when "manual"
      Accessories::Scaling::Manual.new(order_detail)
    when "auto"
      Accessories::Scaling::Auto.new(order_detail)
    else
      Accessories::Scaling::Default.new(order_detail)
    end
  end
end
