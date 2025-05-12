# frozen_string_literal: true

require "rails_helper"
include ActionView::Helpers::NumberHelper
include DateHelper
include TextHelpers::Translation

def translation_scope
  "views.umass_corum.admin_reports.facility_rates"
end

private

def product_status(product)
  product.is_archived? ? "Inactive" : "Active"
end

def duration_rate_step_value(price_policy, field, step)
  return nil unless price_policy.product.duration_pricing_mode?
  return nil unless price_policy.duration_rates.count > step
  price_policy.duration_rates[step][field]
end

def cancellation_charge(price_policy)
  price_policy.full_price_cancellation ? "Yes" : nil
end

def expected_headers
  [
    text(".facility_name"),
    text(".instrument_name"),
    text(".instrument_active"),
    text(".note"),
    text(".start_date"),
    text(".expire_date"),
    text(".billing_mode"),
    text(".pricing_mode"),
    text(".unit_cost"),
    text(".unit_subsidy"),
    text(".usage_rate"),
    text(".minimum_cost"),
    text(".cancellation_cost"),
    text(".usage_subsidy"),
    text(".duration_step_1"),
    text(".duration_rate_1"),
    text(".duration_subsidy_1"),
    text(".duration_step_2"),
    text(".duration_rate_2"),
    text(".duration_subsidy_2"),
    text(".duration_step_3"),
    text(".duration_rate_3"),
    text(".duration_subsidy_3"),
    text(".usage_rate_daily"),
    text(".usage_subsidy_daily"),
    text(".charge_for"),
    text(".full_price_cancellation"),
    text(".price_group_name"),
    text(".price_group_type"),
    text(".price_group_facility"),
    text(".creator"),
    text(".created_at"),
    text(".updated_at"),
    text(".deleted_at"),
  ].join(",").force_encoding("US-ASCII")
end

def expected_line_format(price_policy)
  product = price_policy.product
  price_group = price_policy.price_group
  values = [
     product.facility,
     product,
     product_status(product),
     price_policy.note,
     format_usa_datetime(price_policy.start_date),
     format_usa_datetime(price_policy.expire_date),
     product.billing_mode,
     product.pricing_mode,
     number_to_currency(price_policy.unit_cost),
     number_to_currency(price_policy.unit_subsidy),
     number_to_currency(price_policy.usage_rate),
     number_to_currency(price_policy.minimum_cost),
     number_to_currency(price_policy.cancellation_cost),
     number_to_currency(price_policy.usage_subsidy),
     duration_rate_step_value(price_policy, :min_duration_hours, 0),
     number_to_currency(duration_rate_step_value(price_policy, :rate, 0)),
     number_to_currency(duration_rate_step_value(price_policy, :subsidy, 0)),
     duration_rate_step_value(price_policy, :min_duration_hours, 1),
     number_to_currency(duration_rate_step_value(price_policy, :rate, 1)),
     number_to_currency(duration_rate_step_value(price_policy, :subsidy, 1)),
     duration_rate_step_value(price_policy, :min_duration_hours, 2),
     number_to_currency(duration_rate_step_value(price_policy, :rate, 2)),
     number_to_currency(duration_rate_step_value(price_policy, :subsidy, 2)),
     number_to_currency(price_policy.usage_rate_daily),
     number_to_currency(price_policy.usage_subsidy_daily),
     price_policy.charge_for.titlecase,
     cancellation_charge(price_policy),
     price_group.name,
     price_group.type_string,
     price_group.facility,
     price_policy.created_by,
     format_usa_datetime(price_group.created_at),
     format_usa_datetime(price_group.updated_at),
     format_usa_datetime(price_group.deleted_at),
  ].join(",").force_encoding("US-ASCII")
end

RSpec.describe UmassCorum::AdminReports::FacilityRatesCsvReport do
  let(:facility) { create(:setup_facility, name: "Animal Imaging", abbreviation: "ANIMG") }
  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let(:cancer_center_price_group) { create(:price_group, :cancer_center) }

  subject(:report) { UmassCorum::AdminReports::FacilityRatesCsvReport.new }

  describe "#to_csv" do
    context "with no rates" do
      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0].chomp!).to eq(expected_headers)
       end

      it "sets the filename based on the passed in report name" do
        expect(report.filename).to eq("facility_rates_data.csv")
      end
    end

    context "with schedule rule rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument One", pricing_mode: Instrument::Pricing::SCHEDULE_RULE) }
      let(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: 60)
      end
      let(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: 200)
      end
      let(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: 180, usage_subsidy: 60)
      end

      it "generates a header line and some data lines", :aggregate_failures do
        base_price_policy
        external_price_policy
        cancer_center_price_policy

        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1].chomp!).to eq(expected_line_format(base_price_policy))
        expect(lines[2].chomp!).to eq(expected_line_format(external_price_policy))
        expect(lines[3].chomp!).to eq(expected_line_format(cancer_center_price_policy))
      end
    end

    context "with duration mode rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument Duration Mode", pricing_mode: Instrument::Pricing::DURATION) }
      let(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: 100)
      end
      let(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: 200)
      end
      let(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: 100, usage_subsidy: 10)
      end

      # create duration_rates
      let!(:base_duration_rate) do
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 1, rate: 90, subsidy: 0)
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 2, rate: 80, subsidy: 0)
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 3, rate: 50, subsidy: 0)
      end
      let!(:external_duration_rate) do
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 1, rate: 180, subsidy: 0)
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 2, rate: 160, subsidy: 0)
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 3, rate: 100, subsidy: 0)
      end
      let!(:cancer_center_duration_rate) do
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 1, rate: 90, subsidy: 10)
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 2, rate: 80, subsidy: 12)
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 3, rate: 50, subsidy: 14)
      end
      it "generates a header line and some duration mode data lines", :aggregate_failures do
        base_price_policy
        external_price_policy
        cancer_center_price_policy

        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1].chomp!).to eq(expected_line_format(base_price_policy))
        expect(lines[2].chomp!).to eq(expected_line_format(external_price_policy))
        expect(lines[3].chomp!).to eq(expected_line_format(cancer_center_price_policy))
      end
    end

    context "with daily mode rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument Daily Mode", pricing_mode: Instrument::Pricing::SCHEDULE_DAILY) }
      let(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: nil, usage_rate_daily: 125)
      end
      let(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: nil, usage_rate_daily: 250)
      end
      let(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: nil, usage_rate_daily: 125, usage_subsidy: 25)
      end

      it "generates a header line and some daily rate mode data lines", :aggregate_failures do
        base_price_policy
        external_price_policy
        cancer_center_price_policy

        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1].chomp!).to eq(expected_line_format(base_price_policy))
        expect(lines[2].chomp!).to eq(expected_line_format(external_price_policy))
        expect(lines[3].chomp!).to eq(expected_line_format(cancer_center_price_policy))
      end
    end
  end
end
