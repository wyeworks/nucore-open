# frozen_string_literal: true

require "rails_helper"

RSpec.describe BundleProduct do
  subject(:bundle_product) { FactoryBot.build(:bundle_product, product: product) }

  describe "#quantity" do
    context "with a non-TimedService" do
      let(:product) { FactoryBot.build(:item) }

      it "is an integer greater than 0" do
        is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer
      end

      it "can be greater than 10" do
        bundle_product.quantity = 11
        is_expected.to have(0).errors_on(:quantity)
      end
    end

    context "with a TimedService" do
      let(:product) { FactoryBot.build(:timed_service) }

      it "is an integer greater than 0" do
        is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer
      end

      it "is less than 10" do
        is_expected.to validate_numericality_of(:quantity).is_less_than(10)
      end
    end
  end
end
