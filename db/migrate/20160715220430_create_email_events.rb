# frozen_string_literal: true

class CreateEmailEvents < ActiveRecord::Migration[4.2]

  def change
    create_table :email_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.datetime :last_sent_at, null: false
      t.timestamps
      t.index [:user_id, :key], unique: true
    end
  end

end
