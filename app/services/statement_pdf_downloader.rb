# frozen_string_literal: true

class StatementPdfDownloader
  def initialize(statements)
    @statements = statements
  end

  # Generate PDFs for all statements and return as array of hashes
  # Each hash contains the filename and binary PDF data
  def download_all
    @statements.filter_map do |statement|

      statement_pdf = StatementPdfFactory.instance(statement, download: true)

      {
        filename: statement_pdf.filename,
        data: statement_pdf.render
      }
    rescue => e
      Rails.logger.error("Error generating PDF for statement ##{statement.id}: #{e.message}")
      nil

    end
  end
end
