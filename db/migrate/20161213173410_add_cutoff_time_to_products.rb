# frozen_string_literal: true

class AddCutoffTimeToProducts < ActiveRecord::Migration[4.2]

  def change
    add_column :products, :cutoff_hours, :integer, null: false, default: 0
  end

end
