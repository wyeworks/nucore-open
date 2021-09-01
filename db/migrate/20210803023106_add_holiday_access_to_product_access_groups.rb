# frozen_string_literal: true

class AddHolidayAccessToProductAccessGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :product_access_groups, :allow_holiday_access, :boolean, default: false, null: false
  end
end
