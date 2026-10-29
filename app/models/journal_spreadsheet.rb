# frozen_string_literal: true

require "spreadsheet"

class JournalSpreadsheet
  def self.template_file
    "#{Rails.root}/public/templates/nucore.journal.template.xls"
  end

  def self.write_journal_entry(rows, options = {})
    # worksheet 0, row 1, column 0 (all 0 based) is where the first line of the first entry goes
    book   = Spreadsheet.open(options[:input_file] || JournalSpreadsheet.template_file)
    sheet1 = book.worksheets[0]
    srow   = 1

    # initialize client encoding
    # Spreadsheet.client_encoding = book.encoding
    Spreadsheet.client_encoding = "UTF-8"

    # write journal date
    # sheet1.row(4)[1] = Time.zone.now.strftime("%m/%d/%Y")

    rows.each do |row|
      line = sheet1.row(srow)

      if block_given?
        yield line, row
      else
        line[0] = row.account
        line[1] = sprintf("%.2f", row.amount)
        line[2] = row.description
        line[3] =
          if row.fulfilled_at.present?
            I18n.l(row.fulfilled_at.to_date, format: :journal_line_reference)
          else
            ""
          end
      end

      # increment row
      srow += 1
    end

    # write journal file
    output_file = options[:output_file] || "#{Rails.root}/nucore.journal.#{Time.zone.now.strftime('%Y%m%dT%H%M%S')}.xls"
    book.write(output_file)

    output_file
  end
end
