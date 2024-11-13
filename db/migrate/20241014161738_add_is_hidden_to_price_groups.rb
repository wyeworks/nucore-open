# frozen_string_literal: true

class AddIsHiddenToPriceGroups < ActiveRecord::Migration[7.0]
  def up
    add_column :price_groups, :is_hidden, :boolean, default: false

    if Nucore::Database.oracle?
      execute("UPDATE price_groups SET price_groups.is_hidden = 0")
    else
      execute("UPDATE price_groups SET price_groups.is_hidden = false")
    end

    change_column_null :price_groups, :is_hidden, false
  end

  def down
    remove_column :price_groups, :is_hidden
  end
end
