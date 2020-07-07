class AddSoftDeleteToPriceGroupMember < ActiveRecord::Migration[5.2]
  def change
    change_table :price_group_members do |t|
      t.timestamps null: true # these didn't exist before, so old ones should be allowed to stay null
      t.datetime :deleted_at, index: true
    end
  end
end
