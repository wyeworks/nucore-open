# frozen_string_literal: true

class AddProcessedAtToOrderImport < ActiveRecord::Migration[4.2]

  def up
    add_column :order_imports, :processed_at, :timestamp, after: :created_by

    OrderImport.all.each do |order_import|
      order_import.update_attribute(:processed_at, order_import.created_at)
    end
  end

  def down
    remove_column :order_imports, :processed_at
  end

end
