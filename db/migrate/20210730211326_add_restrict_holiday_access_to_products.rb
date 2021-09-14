# frozen_string_literal: true

class AddRestrictHolidayAccessToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :restrict_holiday_access, :boolean, default: false, null: false
  end
end
