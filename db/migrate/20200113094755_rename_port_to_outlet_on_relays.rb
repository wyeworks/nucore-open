class RenamePortToOutletOnRelays < ActiveRecord::Migration[5.0]
  def change
    rename_column :relays, :port, :outlet
  end
end
