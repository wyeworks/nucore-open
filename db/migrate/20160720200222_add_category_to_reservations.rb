class AddCategoryToReservations < ActiveRecord::Migration

  def change
    add_column :reservations, :category, :string, null: true
  end

end
