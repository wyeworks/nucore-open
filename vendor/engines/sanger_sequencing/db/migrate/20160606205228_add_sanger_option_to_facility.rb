# frozen_string_literal: true

class AddSangerOptionToFacility < ActiveRecord::Migration[4.2]

  def change
    add_column :facilities, :sanger_sequencing_enabled, :boolean, null: false, default: false
  end

end
