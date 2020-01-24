# frozen_string_literal: true

class RemoveUnitSizeAndRenameColumnInProducts < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :products, :unit_size
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
