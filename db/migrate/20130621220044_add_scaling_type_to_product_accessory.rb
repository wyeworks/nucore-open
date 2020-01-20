# frozen_string_literal: true

class AddScalingTypeToProductAccessory < ActiveRecord::Migration[4.2]

  def change
    add_column :product_accessories, :scaling_type, :string, null: false, default: :quantity
  end

end
