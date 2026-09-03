# frozen_string_literal: true

require "rails_helper"

RSpec.describe Estimate do
  describe "price policy validation" do
    let(:facility) { create(:setup_facility) }
    let(:product) { create(:item, facility:) }
    let(:price_group) { create(:price_group) }
    let(:estimate_details_attributes) do
      [{ product_id: product.id, quantity: 1 }]
    end
    let(:subject) do
      build(
        :estimate,
        facility:,
        price_group:,
        user: nil,
        custom_name: "Some name",
        estimate_details_attributes:,
      )
    end

    context "when product has a price for the price group" do
      before do
        create(:item_price_policy, product:, price_group:)
      end

      it { is_expected.to be_valid }
    end

    context "when product does not have a price" do
      it { is_expected.not_to be_valid }

      it "adds correct error" do
        subject.valid?

        expect(subject.errors).to(
          be_added("estimate_details.base", :no_price_policy)
        )
      end
    end
  end
end
