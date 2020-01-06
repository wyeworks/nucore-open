# frozen_string_literal: true

class UserFixProblemReservationFields < ActiveRecord::Migration[5.0]

  def change
    change_table :order_details do |t|
      t.string :problem_description_key_was, null: true
      t.timestamp :problem_resolved_at, null: true
      t.references :problem_resolved_by, foreign_key: { to_table: :users }, index: true, null: true
    end
  end

end
