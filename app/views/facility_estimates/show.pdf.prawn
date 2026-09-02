prawn_document(**@estimate_pdf.prawn_options,
              filename: @estimate_pdf.filename,
              disposition: "attachment") do |pdf|
  PdfFontHelper.set_fonts(pdf)
  @estimate_pdf.generate(pdf)
end
