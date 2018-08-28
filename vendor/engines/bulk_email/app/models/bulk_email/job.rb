# frozen_string_literal: true

module BulkEmail

  class Job < ApplicationRecord

    self.table_name = "bulk_email_jobs"

    belongs_to :facility, foreign_key: :facility_id
    belongs_to :user, foreign_key: :user_id

    serialize :recipients, Array
    serialize :search_criteria, Hash

    validates :user_id,
              :subject,
              :body,
              :recipients,
              :search_criteria, presence: true

  end

end
