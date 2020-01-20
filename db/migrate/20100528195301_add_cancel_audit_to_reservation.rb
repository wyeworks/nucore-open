# frozen_string_literal: true

class AddCancelAuditToReservation < ActiveRecord::Migration[4.2]

  def self.up
    add_column :reservations, :canceled_at,     :datetime,             null: true
    add_column :reservations, :canceled_by,     :integer,              null: true
    add_column :reservations, :canceled_reason, :string, limit: 50, null: true
  end

  def self.down
    remove_column :reservations, :canceled_at
    remove_column :reservations, :canceled_by
    remove_column :reservations, :canceled_reason
  end

end
