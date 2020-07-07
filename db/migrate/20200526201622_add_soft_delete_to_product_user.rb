class AddSoftDeleteToProductUser < ActiveRecord::Migration[5.2]
  def change
    change_table :product_users do |t|
      t.timestamps null: true # these didn't exist before, so old ones should be allowed to stay null
      t.datetime :deleted_at, index: true
    end
  end
end
