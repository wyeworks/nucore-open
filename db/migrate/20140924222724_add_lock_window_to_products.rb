# frozen_string_literal: true

class AddLockWindowToProducts < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :lock_window, :integer, null: false, default: 0
  end

end
