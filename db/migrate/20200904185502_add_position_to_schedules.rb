class AddPositionToSchedules < ActiveRecord::Migration[5.2]
  def change
    change_table :schedules do |t|
      t.integer :position
    end
  end
end
