# frozen_string_literal: true

class CreateScishieldTrainings < ActiveRecord::Migration[7.0]
  def change
    create_table :scishield_trainings do |t|
      t.integer :user_id, null: false
      t.string :course_name, null: false

      t.timestamps
    end
  end
end
