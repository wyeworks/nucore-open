# frozen_string_literal: true

module OrdersPdf
  include ActionView::Helpers::NumberHelper
  include DateHelper

  LABEL_ROW_STYLE = {
    font_style: :bold,
    background_color: "cccccc",
  }.freeze

  def generate(_pdf)
    raise NotImplementedError
  end

  def filename
    raise NotImplementedError
  end

  def render
    pdf = Prawn::Document.new(prawn_options)
    PdfFontHelper.set_fonts(pdf)
    generate(pdf)
    pdf.render
  end

  def prawn_options
    {
      left_margin: 50,
      right_margin: 50,
      top_margin: 50,
      bottom_margin: 75,
      page_size: "LETTER",
    }
  end

  def normalize_whitespace(text)
    WhitespaceNormalizer.normalize(text)
  end
end
