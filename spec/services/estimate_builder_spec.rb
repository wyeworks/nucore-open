# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimateBuilder, type: :service do
  include DateHelper

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:customer_user) { create(:user) }
  let(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group: customer_user.price_groups.first) }
  let(:instrument) { create(:setup_instrument, facility:) }
  let!(:instrument_price_policy) { create(:instrument_price_policy, product: instrument, price_group: customer_user.price_groups.first) }
  let(:bundle) { create(:bundle, facility:, bundle_products: [item, instrument]) }
  let(:expires_at) { 2.days.from_now.strftime("%m/%d/%Y") }
  let(:estimate_params) do
    {
      name: "Test Estimate",
      expires_at:,
      created_by_id: director.id,
      user_id: customer_user.id,
      note: "This is a test estimate",
      estimate_details_attributes:
        {
          "0" => {
            product_id: bundle.id, quantity: 2, duration: 90, duration_unit: "mins"
          }
        }
    }
  end
  let(:estimate_params_attributes) { ActionController::Parameters.new(estimate_params).permit! }

  subject { described_class.new(facility, director) }

  describe "#build_estimate" do
    it "creates an estimate with the correct attributes" do
      estimate = subject.build_estimate(estimate_params_attributes)

      expect(estimate).to be_persisted
      expect(estimate.name).to eq("Test Estimate")
      expect(estimate.expires_at).to eq(parse_usa_date(expires_at))
      expect(estimate.created_by_id).to eq(director.id)
      expect(estimate.user_id).to eq(customer_user.id)
      expect(estimate.note).to eq("This is a test estimate")
      expect(estimate.estimate_details.size).to eq(2)
      instrument_estimate_detail = estimate.estimate_details.find { |detail| detail.product_id == instrument.id }
      item_estimate_detail = estimate.estimate_details.find { |detail| detail.product_id == item.id }

      expect(instrument_estimate_detail.quantity).to eq(2)
      expect(instrument_estimate_detail.duration).to eq(90)
      expect(instrument_estimate_detail.duration_unit).to eq("mins")
      expect(item_estimate_detail.quantity).to eq(2)
      expect(item_estimate_detail.duration).to eq(nil)
      expect(item_estimate_detail.duration_unit).to eq(nil)
    end
  end
end
