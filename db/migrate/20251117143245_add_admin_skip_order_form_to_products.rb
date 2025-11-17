# frozen_string_literal: true

class AddAdminSkipOrderFormToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :admin_skip_order_form, :boolean, default: false, null: false
  end
end
