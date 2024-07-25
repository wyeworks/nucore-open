# frozen_string_literal: true

class AddDepositNumberToOrderDetails < ActiveRecord::Migration[7.0]
  def change
    change_table :order_details do |t|
      t.string :deposit_number, limit: 256
    end
  end
end
