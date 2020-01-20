# frozen_string_literal: true

class CreateSchedules < ActiveRecord::Migration[4.2]

  def self.up
    create_table :schedules do |t|
      t.string :name
      t.integer :facility_id
      t.timestamps
    end

    add_foreign_key :schedules, :facilities, name: "fk_schedules_facility"
    add_index :schedules, ["facility_id"], name: "i_schedules_facility_id"

    add_column :products, :schedule_id, :integer, after: :description
    add_foreign_key :products, :schedules, name: "fk_instruments_schedule"
    add_index :products, ["schedule_id"], name: "i_instruments_schedule_id"

    Instrument.all.each do |instrument|
      schedule = Schedule.create(name: "#{instrument.name} Schedule", facility_id: instrument.facility_id)
      instrument.update_attributes(schedule_id: schedule.id)
    end
  end

  def self.down
    remove_foreign_key :products, name: "fk_instruments_schedule"
    remove_index :products, name: "i_instruments_schedule_id"
    remove_column :products, :schedule_id
    drop_table :schedules
  end

end
