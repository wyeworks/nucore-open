# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::InstrumentUnavailableExportRawReportsController do
  let(:facility) { create(:setup_facility) }
  let(:admin) { create(:user, :administrator) }

  context "csv email report" do
    let(:report_class) { Reports::InstrumentUnavailableExportRaw }
    let(:action) do
      -> { get(:export_all, params: { facility_id: facility.url_name }) }
    end

    before do
      sign_in admin
    end

    include_examples "csv email action"
  end
end
