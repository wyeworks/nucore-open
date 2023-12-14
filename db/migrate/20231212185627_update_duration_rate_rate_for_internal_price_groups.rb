# frozen_string_literal: true

class DurationRate < ApplicationRecord; end

class UpdateDurationRateRateForInternalPriceGroups < ActiveRecord::Migration[7.0]

  def up
    DurationRate.all.each(&:set_rate_from_base)
  end

  # no-op
  def down; end
end
