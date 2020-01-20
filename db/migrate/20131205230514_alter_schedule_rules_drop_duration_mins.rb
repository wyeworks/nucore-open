# frozen_string_literal: true

class AlterScheduleRulesDropDurationMins < ActiveRecord::Migration[4.2]

  def up
    remove_column :schedule_rules, :duration_mins
  end

  def down
    add_column :schedule_rules, :duration_mins, :integer, null: false
  end

end
