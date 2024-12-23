class AddProductStartTimeDisabled < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :start_time_disabled, :boolean, default: false, null: false
  end
end
