# frozen_string_literal: true

class BulkImportJob < ApplicationJob
  def perform(bulk_import)
    bulk_import.status_in_progress!
    if bulk_import.load!
      bulk_import.status_done!
    else
      bulk_import.status_done_errors!
    end
  rescue BulkImportError => e
    bulk_import.status_failed!
  end

  def max_attempts
    1
  end
end
