# frozen_string_literal: true

class UpdateDurationRateRateForInternalPriceGroups < ActiveRecord::Migration[7.0]
  class DurationRate < ApplicationRecord; end

  def up
    DurationRate.all.each(&:set_rate_from_base)
  end

  # no-op
  def down; end
end
