# frozen_string_literal: true

class AddOrderDetailNote < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :note, :string, limit: 25
  end

  def self.down
    # why doesn't oracle_enhanced support remove_column? we'll never know.
    execute <<-SQL
       ALTER TABLE order_details DROP COLUMN note
    SQL
  end

end
