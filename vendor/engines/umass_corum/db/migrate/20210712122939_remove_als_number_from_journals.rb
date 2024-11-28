# frozen_string_literal: true

class RemoveAlsNumberFromJournals < ActiveRecord::Migration[5.2]
  def change
    remove_column :journals, :als_number, :integer
  end
end
