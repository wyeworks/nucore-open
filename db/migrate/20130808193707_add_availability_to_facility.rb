# frozen_string_literal: true

class AddAvailabilityToFacility < ActiveRecord::Migration[4.2]

  def change
    add_column :facilities, :show_instrument_availability, :boolean, default: false, null: false
  end

end
