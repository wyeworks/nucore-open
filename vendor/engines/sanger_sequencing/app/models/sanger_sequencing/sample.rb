# frozen_string_literal: true

module SangerSequencing
  class Sample < ApplicationRecord
    self.table_name = "sanger_sequencing_samples"
    belongs_to :submission, inverse_of: :samples

    validates :customer_sample_id, presence: true

    default_scope { order(:id) }

    def reserved?
      false
    end

    def results_files
      submission.order_detail.sample_results_files.select { |file| file.name.start_with?("#{id}_") }
    end
  end
end
