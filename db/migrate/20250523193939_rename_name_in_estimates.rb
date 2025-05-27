# frozen_string_literal: true

class RenameNameInEstimates < ActiveRecord::Migration[7.0]
  def change
    rename_column :estimates, :name, :description
  end
end
