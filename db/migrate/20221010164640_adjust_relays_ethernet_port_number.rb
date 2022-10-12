class AdjustRelaysEthernetPortNumber < ActiveRecord::Migration[6.1]
  def up
    change_column :relays, :ethernet_port_number, :string
  end

  def down
    change_column :relays, :ethernet_port_number, :integer
  end
end
