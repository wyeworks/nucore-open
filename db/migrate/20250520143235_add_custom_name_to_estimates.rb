# frozen_string_literal: true

class AddCustomNameToEstimates < ActiveRecord::Migration[7.0]
  def change
    add_column :estimates, :custom_name, :string
  end
end
