# frozen_string_literal: true

class StatementPdfDownloader
  def initialize(statements)
    @statements = statements
  end

  def download_all
    # Generate all PDFs and return them as an array of hashes with filename and data
    @statements.map do |statement|
      statement_pdf = StatementPdfFactory.instance(statement, download: true)
      {
        filename: statement_pdf.filename,
        data: statement_pdf.render
      }
    end
  end
end
