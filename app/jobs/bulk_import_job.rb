# frozen_string_literal: true

class BulkImportJob < ApplicationJob
  # Do not retry this job
  retry_on StandardError, attempts: 1

  def perform(bulk_import)
    bulk_import.load!
  end
end
