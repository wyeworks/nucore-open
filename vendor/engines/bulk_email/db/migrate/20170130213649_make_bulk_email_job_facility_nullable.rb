# frozen_string_literal: true

class MakeBulkEmailJobFacilityNullable < ActiveRecord::Migration[4.2]

  def up
    change_column :bulk_email_jobs, :facility_id, :integer, null: true
  end

  def down
    change_column :bulk_email_jobs, :facility_id, :integer, null: false
  end

end
