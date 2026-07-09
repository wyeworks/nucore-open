# frozen_string_literal: true

class RemoveScheduleRulesDiscountPercent < ActiveRecord::Migration[8.0]
  def change
    remove_column(
      :schedule_rules,
      :discount_percent,
      :decimal,
      precision: 10,
      scale: 2,
      default: "0.0",
      null: false,
    )
  end
end
