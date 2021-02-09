class AddObjectChangesToVersions < ActiveRecord::Migration[5.2]
  def change
    change_table :versions do |t|
      t.text :object_changes
    end
  end
end
