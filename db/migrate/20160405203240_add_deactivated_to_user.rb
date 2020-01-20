# frozen_string_literal: true

class AddDeactivatedToUser < ActiveRecord::Migration[4.2]

  def change
    add_column :users, :deactivated_at, :timestamp
  end

end
