# frozen_string_literal: true

class IncreaseDelayedJobsHandlerCapacity < ActiveRecord::Migration[4.2]

  def up
    if NUCore::Database.mysql?
      change_column :delayed_jobs, :handler, :text, limit: (2**32 - 1)
    end
  end

  def down
    if NUCore::Database.mysql?
      change_column :delayed_jobs, :handler, :text
    end
  end

end
