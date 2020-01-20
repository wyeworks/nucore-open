# frozen_string_literal: true

class CreateDelayedJobs < ActiveRecord::Migration[4.2]

  def change
    create_table :delayed_jobs, force: true do |table|
      table.integer  :priority, default: 0, null: false
      table.integer  :attempts, default: 0, null: false
      table.text     :handler, null: false
      table.text     :last_error
      table.datetime :run_at
      table.datetime :locked_at
      table.datetime :failed_at
      table.string   :locked_by
      table.string   :queue
      table.timestamps null: false
    end

    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
  end

end
