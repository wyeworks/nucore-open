# frozen_string_literal: true

class BulkImportPaperclipSupport < ActiveRecord::Migration[8.0]
  def change
    add_attachment :bulk_imports, :file
  end
end
