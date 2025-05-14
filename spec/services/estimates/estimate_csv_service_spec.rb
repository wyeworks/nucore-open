# frozen_string_literal: true

require "rails_helper"

RSpec.describe Estimates::EstimateCsvService do
  include DateHelper

  subject(:csv_string) { described_class.new(estimate).to_csv }

  let(:facility) { create(:setup_facility) }
  let(:other_facility) { create(:setup_facility) }
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:price_group) { user.price_groups.first }
  let(:csv_rows) { CSV.parse(csv_string) }

  let(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) do
    create(:item_price_policy, product: item, price_group:, unit_cost: 100)
  end

  let(:timed_product) { create(:setup_timed_service, facility:) }
  let!(:service_price_policy) do
    create(:timed_service_price_policy, product: timed_product, price_group:)
  end

  let(:other_facility_product) { create(:setup_item, facility: other_facility) }
  let!(:other_facility_price_policy) do
    create(:item_price_policy,
           product: other_facility_product,
           price_group:,
           unit_cost: 80)
  end

  let(:instrument) { create(:setup_instrument, :daily_booking, facility:) }
  let!(:instrument_price_policy) do
    create(:instrument_price_policy,
           product: instrument,
           price_group:,
           usage_rate_daily: 50)
  end

  let(:estimate) do
    create(:estimate,
           user:,
           created_by_user: creator,
           name: "Test Estimate",
           expires_at: 1.week.from_now)
  end

  describe "#to_csv" do
    context "with a basic estimate" do
      before do
        create(:estimate_detail, estimate:, product: item, quantity: 2)
      end

      it "generates the header section correctly" do
        expect(csv_rows[0]).to eq(["Estimate Information"])
        expect(csv_rows[1]).to eq(["ID", "Name", "Created By", "User", "Expiration Date"])
        expect(csv_rows[2]).to eq(
          [
            estimate.id.to_s,
            "Test Estimate",
            creator.full_name,
            user.full_name,
            format_usa_date(estimate.expires_at)
          ]
        )
      end

      it "generates the products section correctly" do
        expect(csv_rows[4]).to eq(%w[Products])
        expect(csv_rows[5]).to eq(%w[Facility Product Quantity Duration Price])
        expect(csv_rows[6]).to eq(
          [
            facility.name,
            item.name,
            "2",
            nil,
            "$200.00"
          ]
        )
      end

      it "includes the total" do
        expect(csv_rows.last).to eq(["Total", "", "", "", "$200.00"])
      end
    end

    context "with a timed service" do
      before do
        create(:estimate_detail,
               estimate:,
               product: timed_product,
               quantity: 1,
               duration: 180,
               duration_unit: "mins")
      end

      it "formats the duration in HH:MM format" do
        expect(csv_rows[6][3]).to eq("3:00")
      end

      it "calculates the right price" do
        expect(csv_rows[6][4]).to eq("$180.00")
      end
    end

    context "with a daily instrument" do
      before do
        create(:estimate_detail,
               estimate:,
               product: instrument,
               quantity: 1,
               duration: 3,
               duration_unit: "days")
      end

      it "formats the duration in days" do
        expect(csv_rows[6][3]).to eq("3 days")
      end

      it "calculates the right price" do
        expect(csv_rows[6][4]).to eq("$150.00")
      end
    end

    context "with products from multiple facilities" do
      before do
        create(:estimate_detail, estimate:, product: item, quantity: 2)
        create(:estimate_detail,
               estimate:,
               product: other_facility_product,
               quantity: 1)
      end

      it "includes facility names with products" do
        expect(csv_rows[6][0..1]).to eq([facility.name, item.name])
        expect(csv_rows[7][0..1]).to eq([other_facility.name, other_facility_product.name])
      end

      it "calculates the total correctly across facilities" do
        expect(csv_rows.last).to eq(["Total", "", "", "", "$280.00"])
      end
    end

    context "with multiple products" do
      before do
        create(:estimate_detail, estimate:, product: item, quantity: 2)
        create(:estimate_detail,
               estimate:,
               product: timed_product,
               quantity: 1,
               duration: 180,
               duration_unit: "mins")
      end

      it "includes the facility name with the product" do
        expect(csv_rows[6][0..1]).to eq([facility.name, item.name])
        expect(csv_rows[7][0..1]).to eq([facility.name, timed_product.name])
      end

      it "calculates the total correctly" do
        expect(csv_rows.last).to eq(["Total", "", "", "", "$380.00"])
      end
    end
  end
end
