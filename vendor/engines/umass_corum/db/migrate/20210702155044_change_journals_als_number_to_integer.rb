# frozen_string_literal: true

class ChangeJournalsAlsNumberToInteger < ActiveRecord::Migration[5.2]
  def up
    change_column :journals, :als_number, :integer
  end

  def down
    change_column :journals, :als_number, :string
  end
end
