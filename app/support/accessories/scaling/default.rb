# frozen_string_literal: true

class Accessories::Scaling::Default < SimpleDelegator
  attr_accessor :enabled

  def to_model
    self
  end

  def order_detail
    __getobj__
  end

  def update_quantity
    order_detail.quantity ||= 1
  end

  def quantity_editable?
    true
  end

  def quantity_as_time?
    false
  end

  def enabled?
    !!@enabled
  end

  def assign_attributes(attrs)
    self.enabled = attrs.delete :enabled if attrs[:enabled]
    order_detail.assign_attributes(attrs)
  end

  # Since this is a decorator, allow comparison with the base OrderDetail
  def ==(other)
    if other.is_a? OrderDetail
      order_detail == other
    else
      equal? other
    end
  end
end
