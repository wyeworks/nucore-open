class ChangeUsersUmassEmplidToUnique < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :umass_emplid, unique: true
  end
end
