# frozen_string_literal: true

class BulkImportJob < ApplicationJob
  def perform(bulk_import)
    bulk_import.load!
  end
end
