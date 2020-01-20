# frozen_string_literal: true

class CreateAlarmEvents < ActiveRecord::Migration[4.2]

  def change
    create_table :secure_rooms_alarm_events do |t|
      t.text :additional_data
      t.string :class_code
      t.string :event_code
      t.string :event_description
      t.string :mac_address
      t.string :message_id
      t.datetime :message_time
      t.string :message_type
      t.string :priority
      t.string :task_code
      t.string :task_description
      t.string :task_description

      t.text :raw_post

      t.timestamps null: false
    end
  end

end
