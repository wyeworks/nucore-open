# frozen_string_literal: true

class AddActiveFacilitiesIndex < ActiveRecord::Migration[4.2]

  def change
    add_index :facilities, [:is_active, :name]
  end

end
