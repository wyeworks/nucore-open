# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[4.2]

  def self.up
    create_table :notifications do |t|
      t.column :type, :string, null: false
      t.column :subject_id, :integer, null: false
      t.column :subject_type, :string, null: false
      t.column :user_id, :integer, null: false
      t.column :notice, :string, null: false
      t.column :dismissed_at, :timestamp
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end

end
