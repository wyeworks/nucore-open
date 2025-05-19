# frozen_string_literal: true

class AddPriceGroupToEstimates < ActiveRecord::Migration[7.0]
  class Estimate < ApplicationRecord
    belongs_to :price_group
    belongs_to :facility
  end

  def change
    add_reference :estimates, :price_group, null: false

    # Populate the Price group for each existing Estimate.
    # Just using the first price group for the facility, as we don't have any estimates in prod yet, so we don't need to worry about the price group.
    Estimate.find_each do |estimate|
      estimate.update(price_group: estimate.facility.price_groups.first)
    end
  end
end
