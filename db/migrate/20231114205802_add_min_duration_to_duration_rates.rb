# frozen_string_literal: true

class AddMinDurationToDurationRates < ActiveRecord::Migration[7.0]

  class DurationRate < ApplicationRecord
    belongs_to :rate_start
  end

  class RateStart < ApplicationRecord; end

  def up
    add_column :duration_rates, :min_duration_hours, :integer, null: true
    DurationRate.joins(:rate_start).each do |dr|
      dr.update!(min_duration_hours: dr.rate_start.min_duration)
    end
    change_column_null :duration_rates, :min_duration_hours, false
  end

  def down
    remove_column :duration_rates, :min_duration_hours
  end

end
