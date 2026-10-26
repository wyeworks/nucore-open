# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::PriceListReport do
  subject(:report) { described_class.new }

  let(:facility) { create(:setup_facility, name: "Animal Imaging") }
  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }

  def rows
    CSV.parse(report.to_csv, headers: true)
  end

  def column(header)
    rows.map { |row| row[header] }
  end

  def base_column(name)
    column("#{base_price_group.name} - #{name}")
  end

  # Headers come from locales a fork may override, so never spell them out here.
  def policy_header(attribute)
    PricePolicy.human_attribute_name(attribute)
  end

  def report_header(key)
    I18n.t("reports.price_list.headers.#{key}")
  end

  def product_header(key, default)
    I18n.t("reports.price_list.headers.#{key}", default:)
  end

  describe "the fiscal year" do
    it "defaults to the current fiscal year" do
      expect(report.fiscal_year).to eq(SettingsHelper.fiscal_year_end.year)
    end

    it "accepts a fiscal year as a string, as the job passes it" do
      year = SettingsHelper.fiscal_year_end.year - 1
      expect(described_class.new(fiscal_year: year.to_s).fiscal_year).to eq(year)
    end

    it "falls back to the current fiscal year when given blank" do
      expect(described_class.new(fiscal_year: "").fiscal_year).to eq(SettingsHelper.fiscal_year_end.year)
    end

    it "falls back to the current fiscal year when given something that is not a year" do
      expect(described_class.new(fiscal_year: "abc").fiscal_year).to eq(SettingsHelper.fiscal_year_end.year)
    end

    it "names the fiscal year in the filename and subject" do
      year = SettingsHelper.fiscal_year_end.year
      expect(report.filename).to eq("price_list_fy#{year}.csv")
      expect(report.description).to include(year.to_s)
    end
  end

  describe "columns" do
    it "leads with the product columns" do
      expect(rows.headers.first(3)).to eq(
        [
          product_header(:facility, Facility.model_name.human),
          report_header(:product_type),
          product_header(:name, Product.model_name.human),
        ]
      )
    end

    it "emits a block of rate columns for every visible price group" do
      expect(rows.headers).to include("#{base_price_group.name} - #{policy_header(:hourly_usage_rate)}")
      expect(rows.headers).to include("#{external_price_group.name} - #{policy_header(:unit_cost)}")
      expect(rows.headers.count { |header| header.end_with?(" - #{policy_header(:usage_rate_daily)}") })
        .to eq(PriceGroup.visible.count)
    end

    it "qualifies a facility price group with the facility abbreviation" do
      other_facility = create(:setup_facility, name: "Bio Imaging")
      create(:price_group, facility:, name: "Shared Rate")
      create(:price_group, facility: other_facility, name: "Shared Rate")

      expect(rows.headers).to include("Shared Rate (#{facility.abbreviation}) - #{policy_header(:unit_cost)}")
      expect(rows.headers).to include("Shared Rate (#{other_facility.abbreviation}) - #{policy_header(:unit_cost)}")
    end
  end

  describe "products" do
    let!(:item) { create(:setup_item, facility:, name: "A Reagent") }

    it "has one row per unarchived product" do
      create(:setup_item, facility:, name: "Z Archived", is_archived: true)

      expect(column(Product.model_name.human)).to eq(["A Reagent"])
    end

    it "reports the facility and the product type" do
      expect(column(Facility.model_name.human)).to eq([facility.to_s])
      expect(column(report_header(:product_type))).to eq([Item.model_name.human])
    end

    it "excludes bundles" do
      create(:bundle, facility:, name: "M Bundle")

      expect(column(Product.model_name.human)).to eq(["A Reagent"])
    end
  end

  describe "a quantity product" do
    let(:item) { create(:setup_item, facility:, name: "A Reagent") }

    before do
      create(:item_price_policy, product: item, price_group: base_price_group, unit_cost: 30, unit_subsidy: 10)
    end

    it "reports the unit cost net of subsidy" do
      expect(base_column(policy_header(:unit_cost))).to eq(["20.0"])
    end

    it "leaves the usage columns blank" do
      expect(base_column(policy_header(:hourly_usage_rate))).to eq([nil])
      expect(base_column(policy_header(:usage_rate_daily))).to eq([nil])
      expect(base_column(report_header(:step_1_start))).to eq([nil])
    end
  end

  describe "a schedule rule instrument" do
    let(:instrument) { create(:setup_instrument, facility:, name: "A Microscope") }

    before do
      create(
        :instrument_price_policy,
        product: instrument,
        price_group: base_price_group,
        usage_rate: 60,
        usage_subsidy: 15,
        minimum_cost: 20,
        cancellation_cost: 5,
      )
    end

    it "reports the hourly usage rate net of subsidy" do
      expect(base_column(policy_header(:hourly_usage_rate))).to eq(["45.0"])
    end

    it "reports the minimum cost net of its proportional subsidy" do
      expect(base_column(policy_header(:minimum_cost))).to eq(["15.0"])
    end

    it "reports the cancellation cost" do
      expect(base_column(report_header(:cancellation_cost))).to eq(["5.0"])
    end

    it "leaves the quantity and daily columns blank" do
      expect(base_column(policy_header(:unit_cost))).to eq([nil])
      expect(base_column(policy_header(:usage_rate_daily))).to eq([nil])
    end
  end

  describe "a stepped instrument" do
    let(:instrument) do
      create(:setup_instrument, facility:, name: "A Microscope", pricing_mode: Instrument::Pricing::DURATION)
    end
    let(:policy) do
      create(
        :instrument_price_policy,
        product: instrument,
        price_group: base_price_group,
        usage_rate: 100,
        usage_subsidy: 0,
      )
    end

    before do
      create(:duration_rate, price_policy: policy, min_duration_hours: 3, rate: 50, subsidy: 0)
      create(:duration_rate, price_policy: policy, min_duration_hours: 1, rate: 90, subsidy: 0)
      create(:duration_rate, price_policy: policy, min_duration_hours: 2, rate: 80, subsidy: 0)
    end

    it "keeps the initial rate in the usage rate column" do
      expect(base_column(policy_header(:hourly_usage_rate))).to eq(["100.0"])
    end

    it "sorts the steps by start hour regardless of creation order" do
      expect(base_column(report_header(:step_1_start))).to eq(["1"])
      expect(base_column(report_header(:step_2_start))).to eq(["2"])
      expect(base_column(report_header(:step_3_start))).to eq(["3"])
    end

    it "reports each step rate net of subsidy" do
      expect(base_column(report_header(:step_1_rate))).to eq(["90.0"])
      expect(base_column(report_header(:step_2_rate))).to eq(["80.0"])
      expect(base_column(report_header(:step_3_rate))).to eq(["50.0"])
    end

  end

  describe "a stepped instrument whose steps have no subsidy" do
    let(:instrument) do
      create(:setup_instrument, facility:, name: "A Microscope", pricing_mode: Instrument::Pricing::DURATION)
    end
    let(:policy) do
      create(
        :instrument_price_policy,
        product: instrument,
        price_group: base_price_group,
        usage_rate: 100,
        usage_subsidy: 0,
      )
    end

    before { create(:duration_rate, price_policy: policy, min_duration_hours: 2, rate: 90) }

    it "reports the step rate instead of erroring the whole row" do
      expect(column(product_header(:name, Product.model_name.human))).to eq(["A Microscope"])
      expect(base_column(report_header(:step_1_start))).to eq(["2"])
      expect(base_column(report_header(:step_1_rate))).to eq(["90.0"])
    end
  end

  describe "a daily booking instrument" do
    let(:instrument) do
      create(:setup_instrument, facility:, name: "A Microscope", pricing_mode: Instrument::Pricing::SCHEDULE_DAILY)
    end

    before do
      create(
        :instrument_price_policy,
        product: instrument,
        price_group: base_price_group,
        usage_rate_daily: 125,
        usage_subsidy_daily: 25,
      )
    end

    it "reports the daily rate net of subsidy" do
      expect(base_column(policy_header(:usage_rate_daily))).to eq(["100.0"])
    end

    it "leaves the hourly usage rate blank" do
      expect(base_column(policy_header(:hourly_usage_rate))).to eq([nil])
    end
  end

  describe "when the price group cannot purchase" do
    let(:item) { create(:setup_item, facility:, name: "A Reagent") }

    before do
      create(:item_price_policy, product: item, price_group: base_price_group, unit_cost: 30, unit_subsidy: 0)
      create(
        :item_price_policy,
        product: item,
        price_group: external_price_group,
        unit_cost: 99,
        unit_subsidy: 0,
        can_purchase: false,
      )
    end

    it "blanks that price group's cells but keeps the others" do
      expect(column("#{external_price_group.name} - #{policy_header(:unit_cost)}")).to eq([nil])
      expect(base_column(policy_header(:unit_cost))).to eq(["30.0"])
    end
  end

  describe "fiscal year scoping" do
    let(:item) { create(:setup_item, facility:, name: "A Reagent") }

    before do
      create(:item_price_policy, product: item, price_group: base_price_group, unit_cost: 30, unit_subsidy: 0)
    end

    it "omits rates from a fiscal year the policies do not cover" do
      past = described_class.new(fiscal_year: SettingsHelper.fiscal_year_end.year - 2)
      past_rows = CSV.parse(past.to_csv, headers: true)

      expect(past_rows.pluck(Product.model_name.human)).to eq(["A Reagent"])
      expect(past_rows.pluck("#{base_price_group.name} - #{policy_header(:unit_cost)}")).to eq([nil])
    end

    it "is named for the year the fiscal year ends in, not the one it starts in" do
      policy = PricePolicy.find_by(product: item, price_group: base_price_group)
      labelled = described_class.new(fiscal_year: SettingsHelper.fiscal_year_end(policy.start_date).year)

      expect(CSV.parse(labelled.to_csv, headers: true)
        .pluck("#{base_price_group.name} - #{policy_header(:unit_cost)}")).to eq(["30.0"])
    end
  end

  describe "the email attributes" do
    it "has an attachment and the shared body" do
      expect(report).to have_attributes(
        has_attachment?: true,
        text_content: I18n.t("reports.csv_export_body"),
      )
    end
  end
end
