# frozen_string_literal: true

class AlterProductAccessoriesAddDeletedAt < ActiveRecord::Migration[4.2]

  def change
    change_table :product_accessories do |t|
      t.datetime :deleted_at
    end
  end

end
