# frozen_string_literal: true

class EstimatePdf
  include OrdersPdf

  attr_reader :estimate

  delegate :facility, to: :estimate

  def initialize(estimate)
    @estimate = estimate
  end

  def filename
    I18n.t(
      "facility_estimate.pdf.filename",
      id: estimate.id,
      facility: facility.abbreviation.gsub(/\s+/, "_"),
    )
  end
end
