# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricePolicyBuilder do
  let(:price_group) { create(:price_group) }
  let!(:facility) { create(:setup_facility) }

  shared_examples "a correctly created PricePolicy" do
    before do
      subject
    end

    it "creates a PricePolicy with the correct attributes" do
      price_policy = PricePolicy.last
      expect(price_policy).to be_present
      expect(price_policy.type).to eq("#{product.type}PricePolicy")
      expect(price_policy.start_date).to be_within(1.day).of(1.month.ago)
      expect(price_policy.expire_date).to be_within(1.day).of(75.years.from_now)
      expect(price_policy.usage_rate).to eq(usage_rate)
      expect(price_policy.minimum_cost).to eq(0)
      expect(price_policy.cancellation_cost).to eq(0)
      expect(price_policy.usage_subsidy).to eq(0)
      expect(price_policy.unit_cost).to eq(0)
      expect(price_policy.unit_subsidy).to eq(0)
      expect(price_policy.can_purchase).to be(true)
      expect(price_policy.note).to eq("Price rule automatically created because of billing mode")
    end
  end

  describe ".create_skip_review_for" do
    subject(:subject) { PricePolicyBuilder.create_skip_review_for(product, price_groups) }

    context "when product is a Service or Item" do
      let(:usage_rate) { nil }

      %w[service item].each do |product_type|
        context "when product is a #{product_type}" do
          let(:product) { create(product_type.to_sym, facility: facility, billing_mode: "Skip Review") }
          let!(:price_groups) { create_list(:price_group, 2) }

          it_behaves_like "a correctly created PricePolicy"
        end
      end
    end

    context "when product is not a Service or Item" do
      let(:product) { create(:instrument, facility: facility, billing_mode: "Skip Review") }
      let!(:price_groups) { create_list(:price_group, 2) }
      let(:usage_rate) { 0 }

      it_behaves_like "a correctly created PricePolicy"
    end

    context "when product is an Instrument with Daily Booking pricing mode" do
      let(:product) do
        create(:instrument,
               facility: facility,
               billing_mode: "Skip Review",
               pricing_mode: Instrument::Pricing::SCHEDULE_DAILY)
      end
      let!(:price_groups) { create_list(:price_group, 2) }
      let!(:usage_rate) { nil }

      before do
        subject
      end

      it "creates PricePolicy with daily rate fields for all price groups" do
        price_groups.each do |pg|
          policy = product.price_policies.find_by(price_group: pg)
          expect(policy).to be_present
          expect(policy.type).to eq("InstrumentPricePolicy")
          expect(policy.usage_rate).to be_nil
          expect(policy.usage_rate_daily).to eq(0)
          expect(policy.usage_subsidy_daily).to eq(0)
          expect(policy.can_purchase?).to be(true)
          expect(policy.note).to eq("Price rule automatically created because of billing mode")
        end
      end
    end
  end

  describe ".create_nonbillable_for" do
    subject(:subject) { PricePolicyBuilder.create_nonbillable_for(product) }
    let!(:price_groups) { [PriceGroup.nonbillable] }

    context "when product is a Service or Item" do
      let(:usage_rate) { nil }

      %w[service item].each do |product_type|
        context "when product is a #{product_type}" do
          let(:product) { create(product_type.to_sym, facility: facility, billing_mode: "Nonbillable") }

          it_behaves_like "a correctly created PricePolicy"
        end
      end
    end

    context "when product is not a Service or Item" do
      let(:product) { create(:instrument, facility: facility, billing_mode: "Nonbillable") }
      let(:usage_rate) { 0 }

      it_behaves_like "a correctly created PricePolicy"
    end
  end
end
