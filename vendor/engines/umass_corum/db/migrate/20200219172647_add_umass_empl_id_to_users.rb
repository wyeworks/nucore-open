class AddUmassEmplIdToUsers < ActiveRecord::Migration[5.2]

  def change
    change_table :users do |t|
      t.string :umass_emplid
    end
  end

end
