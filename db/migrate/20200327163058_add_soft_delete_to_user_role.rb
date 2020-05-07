class AddSoftDeleteToUserRole < ActiveRecord::Migration[5.2]
  def change
    change_table :user_roles do |t|
      t.timestamps null: true # these didn't exist before, so old ones should be allowed to stay null
      t.datetime :deleted_at, index: true
    end
  end
end
