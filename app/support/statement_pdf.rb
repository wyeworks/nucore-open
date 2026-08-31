# frozen_string_literal: true

class StatementPdf
  include OrdersPdf

  attr_reader :statement

  delegate :facility, :account, to: :statement

  def initialize(statement)
    @statement = statement
    # TODO: remove account and facility instance variables in favour
    # of delgate methods. Requires downstream repos to be updated
    @account = statement.account
    @facility = statement.facility
  end

  def filename
    I18n.t(
      "statements.pdf.filename",
      date: I18n.l(@statement.invoice_date, format: :filename_safe),
      facility: @facility.abbreviation.gsub(/\s+/, "_"),
      invoice_number: @statement.invoice_number,
    )
  end
end
