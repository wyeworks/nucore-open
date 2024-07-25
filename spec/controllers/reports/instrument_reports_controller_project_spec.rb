# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::InstrumentReportsController do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:instrument) { FactoryBot.create(:setup_instrument, :timer, facility: facility) }
  let!(:reservation) { FactoryBot.create(:completed_reservation, product: instrument) }
  let!(:no_project_reservation) { FactoryBot.create(:completed_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail }
  let(:project) { FactoryBot.create(:project, facility: facility) }
  let(:user) { FactoryBot.create(:user, :facility_director, facility: facility) }

  describe "the project report" do
    before do
      order_detail.update(project: project)
      sign_in user
      get :index, params: { report_by: :project, facility_id: facility.url_name,
                            date_start: 1.month.ago, date_end: Time.current }, xhr: true
    end

    describe "the project row" do
      let(:row) { assigns[:rows].second }

      it "has the proper data" do
        expect(row.length).to eq(7)
        expect(row.first(3)).to eq([instrument.name, project.name, "1"])
      end
    end

    describe "the non-project row" do
      let(:row) { assigns[:rows].first }

      it "has the proper data" do
        expect(row.length).to eq(7)
        expect(row.first(3)).to eq([instrument.name, " No Project", "1"])
      end
    end
  end
end
