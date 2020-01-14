class AddIpPortToRelays < ActiveRecord::Migration[5.0]
  def change
    add_column :relays, :ip_port, :integer, null: true
  end
end
