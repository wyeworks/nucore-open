class AddFacilityDashboardKey < ActiveRecord::Migration[5.2]
  def change
    change_table :facilities do |t|
      t.string :dashboard_token, index: true
    end
  end
end
