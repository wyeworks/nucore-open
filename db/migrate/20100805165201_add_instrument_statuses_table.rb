# frozen_string_literal: true

class AddInstrumentStatusesTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :instrument_statuses do |t|
      t.references :instrument,      null: false
      t.boolean    :is_on,           null: false
      t.datetime   :created_at,      null: false
    end
    execute "ALTER TABLE instrument_statuses ADD CONSTRAINT fk_int_stats_product FOREIGN KEY (instrument_id) REFERENCES products (id)"
  end

  def self.down
    drop_table :instrument_statuses
  end

end
