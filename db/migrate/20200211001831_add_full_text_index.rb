class AddFullTextIndex < ActiveRecord::Migration[5.2]
  def change
    return unless Nucore::Database.mysql?

    add_index :products, [:name, :description], type: :fulltext
  end
end
