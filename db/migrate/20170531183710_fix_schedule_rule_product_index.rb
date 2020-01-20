# frozen_string_literal: true

class FixScheduleRuleProductIndex < ActiveRecord::Migration[4.2]

  def up
    add_index :schedule_rules, :product_id
  end

end
