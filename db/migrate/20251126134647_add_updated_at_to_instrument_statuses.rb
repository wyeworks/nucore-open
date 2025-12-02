# frozen_string_literal: true

class AddUpdatedAtToInstrumentStatuses < ActiveRecord::Migration[8.0]
  def up
    add_column :instrument_statuses, :updated_at, :datetime

    # Keep only the most recent status for each instrument
    ids_to_keep = ::InstrumentStatus.group(:instrument_id).pluck(Arel.sql("MAX(id)"))
    ::InstrumentStatus.where.not(id: ids_to_keep).delete_all

    # Set updated_at to created_at for remaining records
    execute "UPDATE instrument_statuses SET updated_at = created_at"

    # Remove any existing index on instrument_id alone (Oracle creates these for FKs)
    existing_indexes = connection.indexes(:instrument_statuses)
    existing_indexes.each do |idx|
      if idx.columns == ["instrument_id"]
        remove_index :instrument_statuses, name: idx.name
      end
    end

    # Add unique index on instrument_id to enforce one row per instrument
    add_index :instrument_statuses, :instrument_id, unique: true

    # Remove the old index
    remove_index :instrument_statuses, [:instrument_id, :created_at]
  end

  def down
    add_index :instrument_statuses, [:instrument_id, :created_at]
    remove_index :instrument_statuses, :instrument_id
    remove_column :instrument_statuses, :updated_at
  end
end
