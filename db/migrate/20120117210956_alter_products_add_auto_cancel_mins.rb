# frozen_string_literal: true

class AlterProductsAddAutoCancelMins < ActiveRecord::Migration[4.2]

  def self.up
    add_column :products, :auto_cancel_mins, :integer
  end

  def self.down
    remove_column :products, :auto_cancel_mins
  end

end
