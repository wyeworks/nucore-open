# frozen_string_literal: true

class AddProjectIdToOrderDetail < ActiveRecord::Migration[4.2]

  def change
    add_column :order_details, :project_id, :integer, null: true
  end

end
