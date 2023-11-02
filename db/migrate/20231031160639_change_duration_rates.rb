class ChangeDurationRates < ActiveRecord::Migration[7.0]
  def up
    change_table :duration_rates do |t|
      t.decimal  "subsidy", precision: 16, scale: 8
      t.references :price_group
      t.references :rate_start
    end

    remove_column :duration_rates, :min_duration
    remove_column :duration_rates, :product_id
  end

  def down
    change_table :duration_rates do |t|
      t.integer  "min_duration"
      t.references :product
    end

    remove_column :duration_rates, :subsidy
    remove_column :duration_rates, :price_group_id
    remove_column :duration_rates, :rate_start_id
  end
end
