# frozen_string_literal: true

class AddReplyToToBulkEmailJobs < ActiveRecord::Migration[8.0]

  def change
    add_column :bulk_email_jobs, :reply_to, :string
  end

end
