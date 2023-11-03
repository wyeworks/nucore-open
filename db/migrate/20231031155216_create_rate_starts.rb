class CreateRateStarts < ActiveRecord::Migration[7.0]
  def change
    create_table :rate_starts do |t|
      t.integer  "min_duration"
      t.references :product, type: :integer, foreign_key: true, null: false
      t.timestamps
    end
  end
end
