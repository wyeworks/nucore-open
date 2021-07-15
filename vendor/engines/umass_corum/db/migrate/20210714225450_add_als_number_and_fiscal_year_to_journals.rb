# frozen_string_literal: true

class AddAlsNumberAndFiscalYearToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :journals, :als_number, :integer
    add_column :journals, :fiscal_year, :datetime
    add_index :journals, [:als_number, :fiscal_year], unique: true
  end
end
