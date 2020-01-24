# frozen_string_literal: true

class RemoveReviewableState < ActiveRecord::Migration[4.2]

  def self.up
    reviewable = OrderStatus.find_by(name: "Reviewable")
    inprocess = OrderStatus.in_process
    if inprocess
      execute("UPDATE order_details SET order_status_id=#{inprocess.id},state='inprocess' WHERE order_status_id=#{reviewable.id} AND state='reviewable'")
    end

    if reviewable
      right reviewable.right
      left = reviewable.left
      diff = right - left

      # awesome_nested_set barfs trying to fix descendants on Oracle, so skip its shoddy work and rebuild tree manually
      reviewable.skip_before_destroy = true
      reviewable.destroy

      execute("UPDATE order_statuses SET lft=(lft-(#{diff}+1)), rgt=(rgt-(#{diff}+1)) WHERE lft > #{right}")
    end
  end

  def self.down
    OrderStatus.create!(name: "Reviewable")
  end

end
