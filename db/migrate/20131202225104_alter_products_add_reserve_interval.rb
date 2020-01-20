# frozen_string_literal: true

class AlterProductsAddReserveInterval < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :reserve_interval, :integer
  end

end
