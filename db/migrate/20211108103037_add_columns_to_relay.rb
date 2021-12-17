class AddColumnsToRelay < ActiveRecord::Migration[6.0]
  def change
    add_column :relays, :mac_address, :string, null: true
    add_column :relays, :building_room_number, :string, null: true
    add_column :relays, :circuit_number, :string, null: true
    add_column :relays, :ethernet_port_number, :integer, null: true
  end
end
