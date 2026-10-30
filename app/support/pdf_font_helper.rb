# frozen_string_literal: true

class PdfFontHelper
  FONT_DIR = Rails.root.join("app", "assets", "fonts")

  def self.set_fonts(pdf)
    font_name = Settings.statement_pdf.font_name
    return if font_name.blank?

    pdf.font_families.update(
      font_name => {
        normal: FONT_DIR.join("#{font_name}-Regular.ttf"),
        bold: FONT_DIR.join("#{font_name}-Bold.ttf"),
        italic: FONT_DIR.join("#{font_name}-Italic.ttf"),
      },
    )
    pdf.font(font_name)
  end
end
