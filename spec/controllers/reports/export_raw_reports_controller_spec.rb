# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ExportRawReportsController do
  let(:facility) { create(:setup_facility) }
  let(:user) { create(:user, :administrator) }

  context "csv report by email" do
    let(:report_class) { Reports::ExportRaw }
    let(:action) do
      -> { get(:export_all, params: { facility_id: facility.url_name }) }
    end

    before do
      sign_in user
    end

    include_examples "csv email action"
  end

end
