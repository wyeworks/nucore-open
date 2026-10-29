# frozen_string_literal: true

class AddMissingIndexesForTimelinePages < ActiveRecord::Migration[5.0]
  def change
    add_index :products, [:type, :is_archived, :schedule_id]
    add_index :reservations, %i[type deleted_at product_id reserve_start_at reserve_end_at], name: "reservations_for_timeline"
  end
end
