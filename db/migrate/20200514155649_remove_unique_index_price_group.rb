class RemoveUniqueIndexPriceGroup < ActiveRecord::Migration[5.2]
  def up
    remove_foreign_key :price_groups, :facilities
    remove_index :price_groups, [:facility_id, :name]
    add_foreign_key :price_groups, :facilities
    add_index :price_groups, [:facility_id, :name], unique: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
