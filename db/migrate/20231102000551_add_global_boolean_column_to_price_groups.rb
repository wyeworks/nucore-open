# frozen_string_literal: true

class AddGlobalBooleanColumnToPriceGroups < ActiveRecord::Migration[7.0]

  def up
    change_table :price_groups do |t|
      add_column :price_groups, :global, :boolean, null: false, default: false
      execute <<-SQL
        UPDATE price_groups SET price_groups.global = true
        WHERE price_groups.deleted_at IS NULL
        AND price_groups.facility_id IS NULL
      SQL
    end
  end

  def down
    change_table :price_groups do |t|
      remove_column :price_groups, :global
    end
  end

end
