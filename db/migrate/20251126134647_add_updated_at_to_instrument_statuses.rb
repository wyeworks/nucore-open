# frozen_string_literal: true

class AddUpdatedAtToInstrumentStatuses < ActiveRecord::Migration[8.0]
  def up
    add_column :instrument_statuses, :updated_at, :datetime

    # Set updated_at to created_at for existing records
    execute "UPDATE instrument_statuses SET updated_at = created_at"

    # Keep only the most recent status for each instrument
    execute <<-SQL.squish
      DELETE FROM instrument_statuses
      WHERE id NOT IN (
        SELECT id FROM (
          SELECT MAX(id) as id
          FROM instrument_statuses
          GROUP BY instrument_id
        ) AS latest
      )
    SQL

    # Add unique index on instrument_id to enforce one row per instrument
    # This must be done BEFORE removing the old index to satisfy the foreign key constraint
    add_index :instrument_statuses, :instrument_id, unique: true

    # Remove the old composite index
    remove_index :instrument_statuses, [:instrument_id, :created_at]
  end

  def down
    # Add the old index back BEFORE removing the unique index to satisfy the foreign key constraint
    add_index :instrument_statuses, [:instrument_id, :created_at]
    remove_index :instrument_statuses, :instrument_id
    remove_column :instrument_statuses, :updated_at
  end
end
