class FixScheduleRuleProductIndex < ActiveRecord::Migration

  def up
    add_index :schedule_rules, :product_id
  end

end
