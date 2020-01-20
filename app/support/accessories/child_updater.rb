# frozen_string_literal: true

class Accessories::ChildUpdater

  def initialize(order_detail)
    @order_detail = order_detail
  end

  # Used in OrderDetail after_save hook
  def update_children
    @order_detail.child_order_details.each_with_object([]) do |child, changed|
      update_child(child)
      changed << child if child.has_changes_to_save?
      save_order_detail(child)
    end
  end

  private

  def save_order_detail(child)
    if status_changed?(child)
      change_status! child
    else
      child.save
    end
  end

  def status_changed?(child)
    @order_detail.saved_change_to_order_status_id? && @order_detail.order_status_id_before_last_save == child.order_status_id
  end

  def change_status!(child)
    if @order_detail.complete? && child.fulfilled_at.nil?
      child.backdate_to_complete! @order_detail.fulfilled_at
    else
      child.update_order_status! @order_detail.order_status_updated_by, @order_detail.order_status
    end
  end

  def update_child(child)
    decorated_child = Accessories::Scaling.decorate(child)
    child.account = @order_detail.account
    decorated_child.update_quantity
  end

end
