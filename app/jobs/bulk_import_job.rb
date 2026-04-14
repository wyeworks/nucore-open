# frozen_string_literal: true

class BulkImportJob < ApplicationJob
  def perform(bulk_import)
    bulk_import.load!
  end

  def max_attempts
    1
  end
end
