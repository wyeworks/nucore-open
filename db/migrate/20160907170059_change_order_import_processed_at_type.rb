# frozen_string_literal: true

# This has no effect in MySQL, but corrects a timezone issue in Oracle.
class ChangeOrderImportProcessedAtType < ActiveRecord::Migration[4.2]

  def up
    change_column :order_imports, :processed_at, :datetime
  end

  def down
    change_column :order_imports, :processed_at, :timestamp
  end

end
