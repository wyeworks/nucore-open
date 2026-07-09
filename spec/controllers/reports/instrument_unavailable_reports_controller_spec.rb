# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::InstrumentUnavailableReportsController do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:instruments) { FactoryBot.create_list(:setup_instrument, 3, facility: facility) }
  let(:params) do
    {
      facility_id: facility.url_name,
      date_start: date_start.to_date.iso8601,
      date_end: date_end.to_date.iso8601,
      report_by: :instrument_unavailable,
    }
  end
  let(:user) { FactoryBot.create(:user, :administrator) }

  before { sign_in(user) }

  shared_examples_for "it sets the required instance variables" do
    it { expect(assigns(:label_columns)).to eq(5) }
    it { expect(assigns(:numeric_columns)).to eq [3, 4] }
    it { expect(assigns(:rows)).to be_kind_of(Array) }
    it { expect(assigns(:totals)).to be_kind_of(Array) }
  end

  context "when reporting a 5 day period" do
    let(:date_start) { Time.zone.local(2016, 7, 11).to_date }
    let(:date_end) { Time.zone.local(2016, 7, 15).to_date }

    context "with an instrument with 2 out_of_order incidents totalling 72 hours" do
      before(:each) do
        FactoryBot.create(:offline_reservation,
                          :out_of_order,
                          product: instruments.first,
                          reserve_start_at: date_start.beginning_of_day,
                          duration: 2.days)
        FactoryBot.create(:offline_reservation,
                          :out_of_order,
                          product: instruments.first,
                          reserve_start_at: (date_start + 3.days).beginning_of_day,
                          duration: 1.day)
      end

      context "and an instrument with 1 maintenance incident totalling 24 hours" do
        before(:each) do
          FactoryBot.create(:offline_reservation,
                            :maintenance,
                            product: instruments.second,
                            reserve_start_at: (date_start + 1.day).beginning_of_day,
                            duration: 1.day)
        end

        context "with two instruments each with admin reservations of 24 hours each" do
          before(:each) do
            FactoryBot.create(:admin_reservation,
                              product: instruments.first,
                              reserve_start_at: (date_start + 2.days).beginning_of_day,
                              duration: 1.day,
                              category: nil)
            FactoryBot.create(:admin_reservation,
                              product: instruments.third,
                              reserve_start_at: (date_start + 1.day).beginning_of_day,
                              duration: 3.days,
                              category: nil)
            get(:index, params: params, xhr: true)
          end

          it_behaves_like "it sets the required instance variables"

          it "generates the expected rows" do

            expect(assigns(:rows)).to match_array [
              [instruments.first.to_s,  "Admin",   "",             1, "24.00"],
              [instruments.first.to_s,  "Offline", "Out of Order", 2, "72.00"],
              [instruments.second.to_s, "Offline", "Maintenance",  1, "24.00"],
              [instruments.third.to_s,  "Admin",   "",             1, "72.00"],
            ]
            expect(assigns(:totals)).to eq ["", "", 5, "192.00"]
          end
        end
      end
    end

    context "when hours as decimal would go beyond two decimal places" do
      let(:reserve_start_at) { date_start.beginning_of_day }
      let(:reserve_end_at) { reserve_start_at + 40.minutes }

      before(:each) do
        FactoryBot.create(:offline_reservation,
                          product: instruments.first,
                          reserve_start_at: reserve_start_at,
                          reserve_end_at: reserve_end_at)
        get(:index, params: params, xhr: true)
      end

      it_behaves_like "it sets the required instance variables"

      it "rounds to hundreths" do
        expect(assigns(:rows).first[-1]).to eq("0.67")
      end
    end

    context "when an offline incident began before the report's date_start" do
      let(:reserve_start_at) { (date_start - 1.week).beginning_of_day }

      before(:each) do
        FactoryBot.create(:offline_reservation,
                          product: instruments.first,
                          reserve_start_at: reserve_start_at,
                          reserve_end_at: reserve_end_at)
        get(:index, params: params, xhr: true)
      end

      context "and the instrument is still offline" do
        let(:reserve_end_at) { nil }

        it_behaves_like "it sets the required instance variables"

        it "reports only the downtime during the report range" do
          expect(assigns(:rows)).to match_array [
            [instruments.first.to_s, "Offline", "Out of Order", 1, "120.00"],
          ]
        end
      end

      context "and ended before the report's date_end" do
        let(:reserve_end_at) { (date_end - 1.day).end_of_day }

        it_behaves_like "it sets the required instance variables"

        it "reports only the downtime during the report range" do
          expect(assigns(:rows)).to match_array [
            [instruments.first.to_s, "Offline", "Out of Order", 1, "96.00"],
          ]
        end
      end

      context "and ended after the report's date_end" do
        let(:reserve_end_at) { (date_end + 1.day).end_of_day }

        it_behaves_like "it sets the required instance variables"

        it "reports only the downtime during the report range" do
          expect(assigns(:rows)).to match_array [
            [instruments.first.to_s, "Offline", "Out of Order", 1, "120.00"],
          ]
        end
      end
    end
  end
end
