# frozen_string_literal: true

class AddUserToStoredFile < ActiveRecord::Migration[6.1]
  def change
    add_column :stored_files, :user_id, :integer
  end
end
