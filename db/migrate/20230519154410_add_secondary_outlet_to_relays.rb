# frozen_string_literal: true

class AddSecondaryOutletToRelays < ActiveRecord::Migration[6.1]
  def change
    add_column :relays, :secondary_outlet, :integer
  end
end
