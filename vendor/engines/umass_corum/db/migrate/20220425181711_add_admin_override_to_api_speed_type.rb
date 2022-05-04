class AddAdminOverrideToApiSpeedType < ActiveRecord::Migration[6.1]
  def change
    add_column :umass_corum_api_speed_types, :date_added_admin_override, :datetime
  end
end
