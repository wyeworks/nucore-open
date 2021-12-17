class AddFieldsToSecureRooms < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :card_reader_room_number, :string
    add_column :products, :card_reader_circuit_number, :string
    add_column :products, :card_reader_port_number, :integer
    add_column :products, :card_reader_location_description, :text
    add_column :products, :tablet_room_number, :string
    add_column :products, :tablet_circuit_number, :string
    add_column :products, :tablet_port_number, :integer
    add_column :products, :tablet_location_description, :text
  end
end
