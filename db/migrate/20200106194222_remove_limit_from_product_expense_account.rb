
class RemoveLimitFromProductExpenseAccount < ActiveRecord::Migration[5.0]

  def up
    change_column :products, :account, :string, limit: nil
  end

  def down
    change_column :products, :account, :string, limit: 5
  end

end
