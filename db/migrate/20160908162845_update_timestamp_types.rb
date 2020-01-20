# frozen_string_literal: true

# No effect on MySQL, but important for oracle so times are returned with zones.
class UpdateTimestampTypes < ActiveRecord::Migration[4.2]

  def up
    change_column :users, :deactivated_at, :datetime
    change_column :notifications, :dismissed_at, :datetime
  end

  def down
    change_column :users, :deactivated_at, :timestamp
    change_column :notifications, :dismissed_at, :timestamp
  end

end
