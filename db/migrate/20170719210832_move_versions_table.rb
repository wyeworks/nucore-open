# frozen_string_literal: true

class MoveVersionsTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :versions, :vestal_versions
  end
end
