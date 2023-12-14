# frozen_string_literal: true

require "rails_helper"

RSpec.describe DurationRate do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility:, pricing_mode: "Duration") }
  let(:cancer_center) { create(:price_group, :cancer_center) }
  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let(:base_price_policy) { create(:instrument_price_policy, price_group: base_price_group, product: instrument) }
  let(:cancer_center_price_policy) { create(:instrument_price_policy, price_group: cancer_center, product: instrument) }
  let(:external_price_policy) { create(:instrument_price_policy, price_group: external_price_group, product: instrument) }

  let!(:base_duration_rate_1) { create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 1, rate: 9 / 60.0) }
  let!(:base_duration_rate_2) { create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 2, rate: 9 / 60.0) }
  let!(:base_duration_rate_3) { create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 3, rate: 9 / 60.0) }

  let!(:cancer_center_duration_rate_1) { build(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 1, subsidy: 9 / 60.0, rate: nil) }
  let!(:cancer_center_duration_rate_2) { build(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 2, subsidy: 9 / 60.0, rate: nil) }
  let!(:cancer_center_duration_rate_3) { build(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 3, subsidy: 9 / 60.0, rate: nil) }

  let!(:external_duration_rate_1) { create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 1, rate: 9 / 60.0) }
  let!(:external_duration_rate_2) { create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 2, rate: 9 / 60.0) }
  let!(:external_duration_rate_3) { create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 3, rate: 9 / 60.0) }

  describe "#set_rate_from_base" do

    context "when the price group is base internal" do
      it "does not change the rate" do
        expect { base_duration_rate_2.set_rate_from_base }
          .not_to change(base_duration_rate_2, :rate)
        end
      end

    context "when the price group is internal but not master" do
      it "sets the rate to the base rate" do
        old_rate = cancer_center_duration_rate_1.rate

        expect { cancer_center_duration_rate_1.set_rate_from_base }
        .to change(cancer_center_duration_rate_1, :rate)
        .from(old_rate)
        .to(cancer_center_price_policy.usage_rate)
      end
    end

    context "when the price group is external" do
      it "does not change the rate" do
        expect { external_duration_rate_3.set_rate_from_base }
          .not_to change(external_duration_rate_3, :rate)
      end
    end
  end

end
