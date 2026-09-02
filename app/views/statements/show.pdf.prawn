prawn_document(**@statement_pdf.prawn_options,
              filename: @statement_pdf.filename,
              disposition: "attachment") do |pdf|
  PdfFontHelper.set_fonts(pdf)
  @statement_pdf.generate(pdf)
end
