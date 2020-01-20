# frozen_string_literal: true

class CreateBulkEmailJobs < ActiveRecord::Migration[4.2]

  def change
    create_table :bulk_email_jobs do |t|
      t.references :facility, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :subject, null: false
      t.text :body, null: false
      t.text :recipients, null: false
      t.text :search_criteria, null: false
      t.timestamps null: false
    end
  end

end
