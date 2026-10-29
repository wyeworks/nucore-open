# frozen_string_literal: true

class AddExpiredToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :expired_at, :datetime
    add_column :users, :expired_note, :string
    add_index :users, :expired_at
  end
end
