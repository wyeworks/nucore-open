class AddFullTextIndex < ActiveRecord::Migration[5.2]
  def change
    if Nucore::Database.mysql?
      add_index :products, [:name, :description], type: :fulltext
    end
  end
end
