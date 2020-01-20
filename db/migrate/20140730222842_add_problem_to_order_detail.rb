# frozen_string_literal: true

class AddProblemToOrderDetail < ActiveRecord::Migration[4.2]

  def change
    add_column :order_details, :problem, :boolean, null: false, default: false
    OrderDetail.find_each do |od|
      od.set_problem_order
      od.update_column(:problem, od.problem) ## skip callbacks/validations/timestamps
    end
  end

end
