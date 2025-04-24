# frozen_string_literal: true

class AddDurationToEstimationDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :estimate_details, :duration, :integer
    add_column :estimate_details, :duration_unit, :string
  end
end
