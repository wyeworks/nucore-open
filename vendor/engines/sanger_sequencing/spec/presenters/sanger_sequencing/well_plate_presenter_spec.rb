# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::WellPlatePresenter, feature_setting: { well_plate_alternative_csv_format: false } do
  let(:submission) { create(:sanger_sequencing_submission, order_detail:) }
  let(:samples) { FactoryBot.build_stubbed_list(:sanger_sequencing_sample, 10, submission:) }
  let(:order_detail) { create(:order_detail, order:, product:) }
  let(:order) { create(:purchased_order, product:) }
  let(:product) { create(:setup_instrument) }

  describe "sample_rows" do
    let(:mapping) do
      {
        "A01" => "reserved",
        "A03" => samples[7].id,
        "B01" => samples[0].id,
        "B02" => "",
        "C01" => samples[1].id,
        "D01" => samples[2].id,
        "E01" => samples[3].id,
        "F01" => samples[4].id,
        "G01" => samples[5].id,
        "H01" => samples[6].id,
      }
    end

    let(:well_plate) { SangerSequencing::WellPlate.new(mapping, samples: samples) }
    let(:sample_rows) { presenter.sample_rows }

    describe "for a default sanger plate" do
      let(:presenter) { described_class.new(well_plate, "") }
      let(:expected_results_group) { a_kind_of(String) }
      let(:expected_instrument_protocol) { a_kind_of(String) }
      let(:expected_analysis_protocol) { a_kind_of(String) }

      it "renders" do
        expect(sample_rows[0]).to match(["A01", "", "", expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[1]).to match(["B01", samples[0].id.to_s, samples[0].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[2]).to match(["C01", samples[1].id.to_s, samples[1].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[3]).to match(["D01", samples[2].id.to_s, samples[2].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[4]).to match(["E01", samples[3].id.to_s, samples[3].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[5]).to match(["F01", samples[4].id.to_s, samples[4].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[6]).to match(["G01", samples[5].id.to_s, samples[5].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[7]).to match(["H01", samples[6].id.to_s, samples[6].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[8]).to match(["A03", samples[7].id.to_s, samples[7].customer_sample_id.to_s, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
      end
    end

    describe "for a fragment analysisplate" do
      let(:presenter) { described_class.new(well_plate, :fragment) }
      let(:extra_columns) { ["GS500", "", "", "", "", "None", "", "Sample", "Microsatellite Default", "FragAnalysis_Results_Group", "GeneMapper_50_POP7"] }

      it "renders" do
        expect(sample_rows[0]).to match(["A01", "", ""] + extra_columns)
        expect(sample_rows[1]).to match(["B01", samples[0].id.to_s, samples[0].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[2]).to match(["C01", samples[1].id.to_s, samples[1].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[3]).to match(["D01", samples[2].id.to_s, samples[2].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[4]).to match(["E01", samples[3].id.to_s, samples[3].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[5]).to match(["F01", samples[4].id.to_s, samples[4].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[6]).to match(["G01", samples[5].id.to_s, samples[5].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[7]).to match(["H01", samples[6].id.to_s, samples[6].customer_sample_id.to_s] + extra_columns)
        expect(sample_rows[8]).to match(["A03", samples[7].id.to_s, samples[7].customer_sample_id.to_s] + extra_columns)
      end
    end

    context "when well_plate_alternative_csv_format is enabled", feature_setting: { well_plate_alternative_csv_format: true } do
      let(:presenter) { described_class.new(well_plate, "") }
      let(:expected_results_group) { a_kind_of(String) }
      let(:expected_instrument_protocol) { a_kind_of(String) }
      let(:expected_analysis_protocol) { a_kind_of(String) }
      
      it "renders using alternative_csv_columns" do
        expect(sample_rows[0]).to match(["A01", "PGEM_F", "CQLS", expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[1]).to match(["B01", samples[0].id.to_s, samples[0].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[2]).to match(["C01", samples[1].id.to_s, samples[1].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[3]).to match(["D01", samples[2].id.to_s, samples[2].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[4]).to match(["E01", samples[3].id.to_s, samples[3].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[5]).to match(["F01", samples[4].id.to_s, samples[4].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[6]).to match(["G01", samples[5].id.to_s, samples[5].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[7]).to match(["H01", samples[6].id.to_s, samples[6].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
        expect(sample_rows[8]).to match(["A03", samples[7].id.to_s, samples[7].submission.order_detail.user.username, expected_results_group, expected_instrument_protocol, expected_analysis_protocol])
      end
    end
  end
end
