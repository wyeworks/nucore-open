# frozen_string_literal: true

class ChangeNoteLimitForOrderDetails < ActiveRecord::Migration[4.2]

  def up
    add_column :order_details, :temp_note, :text
    execute("UPDATE order_details SET temp_note = note")
    remove_column :order_details, :note
    rename_column :order_details, :temp_note, :note
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
