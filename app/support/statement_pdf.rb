# frozen_string_literal: true

class StatementPdf

  include ActionView::Helpers::NumberHelper
  include DateHelper

  LABEL_ROW_STYLE = { font_style: :bold, background_color: "cccccc" }.freeze

  DEFAULT_OPTIONS = {
    left_margin: 50,
    right_margin: 50,
    top_margin: 50,
    bottom_margin: 75,
    page_size: "LETTER", # "A4" is now the default size in prawn-rails
  }.freeze

  def initialize(statement, download: false)
    @statement = statement
    @account = statement.account
    @facility = statement.facility
    @download = download
  end

  def generate(_pdf)
    raise NotImplementedError
  end

  def render
    pdf = Prawn::Document.new(options)
    PdfFontHelper.set_fonts(pdf)
    generate(pdf)
    pdf.render
  end

  def download?
    @download
  end

  def normalize_whitespace(text)
    WhitespaceNormalizer.normalize(text)
  end

  def filename
    date = I18n.l(@statement.created_at.to_date, format: :usa_filename_safe)
    I18n.t("statements.pdf.filename", date: date,
                                      facility: @facility.abbreviation.gsub(/\s+/, "_"),
                                      invoice_number: @statement.invoice_number)
  end

  def options
    if download?
      DEFAULT_OPTIONS.merge(filename: filename, disposition: "attachment")
    else
      DEFAULT_OPTIONS.dup
    end
  end

end
