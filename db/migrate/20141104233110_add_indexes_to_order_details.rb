# frozen_string_literal: true

class AddIndexesToOrderDetails < ActiveRecord::Migration[4.2]

  def change
    add_index :order_details, :assigned_user_id
    add_index :order_details, :order_status_id
    add_index :order_details, :response_set_id
    add_index :order_details, :group_id
    add_index :order_details, :statement_id
    add_index :order_details, :journal_id
    add_index :order_details, :state
  end

end
