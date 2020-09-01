class AddFullTextIndexForOracle < ActiveRecord::Migration[5.2]

  def change
    if Nucore::Database.oracle?
      reversible do |dir|
        dir.up do
          add_context_index :products, :name, sync: "ON COMMIT"
          add_context_index :products, :description, sync: "ON COMMIT"
        end
        dir.down do
          remove_context_index :products, :name
          remove_context_index :products, :description
        end
      end
    end
  end

end
