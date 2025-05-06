# frozen_string_literal: true

class StatementPdfDownloader
  def initialize(statements)
    @statements = statements
  end

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

  def handle_download_response(controller, fallback_path)
    pdfs = download_all
    controller.instance_variable_set(:@pdfs, pdfs)

    controller.respond_to do |format|
      format.html do
        controller.flash[:notice] = I18n.t("statements.downloading_multiple", count: pdfs.length)
        controller.redirect_back(fallback_location: fallback_path)
      end

      format.json do
        simplified_pdfs = pdfs.map do |pdf|
          {
            filename: pdf[:filename],
            data: Base64.strict_encode64(pdf[:data])
          }
        end
        controller.render json: { pdfs: simplified_pdfs }
      end

      format.pdf do
        controller.send_data pdfs.first[:data],
                            filename: pdfs.first[:filename],
                            type: 'application/pdf',
                            disposition: 'attachment'
      end
    end
  end
end
