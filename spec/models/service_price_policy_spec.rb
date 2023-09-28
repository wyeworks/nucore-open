# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePricePolicy do
  it "should create a price policy for tomorrow if no policies already exist for that day" do
    is_expected.to allow_value(Date.today + 1).for(:start_date)
  end

  it "should create a price policy for yesterday" do
    is_expected.to allow_value(Date.today - 1).for(:start_date)
  end

  it "should return cost - subsidy as the total" do
    ipp = ServicePricePolicy.new(unit_cost: 10.75, unit_subsidy: 0)
    expect(ipp.unit_total.to_f).to eq(10.75)
    ipp = ServicePricePolicy.new(unit_cost: 10.75, unit_subsidy: 0.75)
    expect(ipp.unit_total.to_f).to eq(10)
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:unit_cost) }
    it { is_expected.to validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:unit_subsidy).is_greater_than_or_equal_to(0) }

    it "should not allow a subsidy more than cost" do
      pp = FactoryBot.build(:item_price_policy, unit_subsidy: 10, unit_cost: 5)
      expect(pp).not_to be_valid
      expect(pp.errors.attribute_names).to be_include :unit_subsidy
    end
  end

  context "test requiring services" do
    before(:each) do
      @facility = FactoryBot.create(:facility)
      @facility_account = FactoryBot.create(:facility_account, facility: @facility)
      @price_group = FactoryBot.create(:price_group, facility: @facility)
      @service = FactoryBot.create(:service, facility_account: @facility_account)
      @price_group_product = FactoryBot.create(:price_group_product, product: @service, price_group: @price_group, reservation_window: nil)
    end

    it "has a valid using factory" do
      # price policy belongs to an service and a price group
      ipp = build(:service_price_policy, product: @service, price_group: @price_group)
      expect(ipp).to be_valid
    end

    it "sets the inverse association correctly return the item" do
      ipp = @service.service_price_policies.create!(FactoryBot.attributes_for(:service_price_policy, price_group: @price_group))
      expect(ipp.product).to eq(@service)
    end

    it "is valid for today if no active price policy already exists" do
      is_expected.to allow_value(Date.today).for(:start_date)
      ipp = create(:service_price_policy, product: @service, start_date: Date.today - 7, expire_date: Date.today - 6,
                                          price_group: @price_group)
      ipp.save(validate: false)
      ipp_new = build(:service_price_policy, product: @service, start_date: Date.today, expire_date: 1.day.from_now,
                                             price_group: @price_group)
      expect(ipp_new).to be_valid
      expect(ipp_new.errors_on(:start_date)).not_to be_nil
    end

    it "is invalid for a day that a policy already exists for" do
      ipp = create(:service_price_policy, product: @service, start_date: Date.today + 7, price_group: @price_group)
      ipp_new = build(:service_price_policy, product: @service, start_date: Date.today + 7, price_group: @price_group)
      expect(ipp_new).to be_invalid
      expect(ipp_new.errors_on(:start_date)).to be_present
    end

    it "calculates the cost for an 1 service" do
      ipp = build(:service_price_policy, product: @service, unit_cost: 10.75, unit_subsidy: 0.75)
      costs = ipp.calculate_cost_and_subsidy
      expect(costs[:cost].to_f).to eq(10.75)
      expect(costs[:subsidy].to_f).to eq(0.75)
    end

    it "calculates the cost for multiple service when given a quantity" do
      ipp = build(:service_price_policy, product: @service, unit_cost: 10.75, unit_subsidy: 0.75)
      costs = ipp.calculate_cost_and_subsidy(2)
      expect(costs[:cost].to_f).to eq(21.5)
      expect(costs[:subsidy].to_f).to eq(1.5)
    end

    it "estimates the same as it calculates" do
      ipp = build(:service_price_policy, product: @service, unit_cost: 10.75, unit_subsidy: 0.75)
      expect(ipp.estimate_cost_and_subsidy(2)).to eq(ipp.calculate_cost_and_subsidy(2))
    end

    it "returns a cost of nil if the purchase is restricted" do
      @price_group_product.destroy
      ipp = build(:service_price_policy, product: @service, price_group: @price_group, can_purchase: false)
      expect(ipp.calculate_cost_and_subsidy).to be_nil
    end

    it "returns the date for the current policies" do
      spp = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day - 7.days, price_group: @price_group)
      spp2 = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day + 7.days, price_group: @price_group)
      expect(ServicePricePolicy.current_date(@service)).to eq(spp.start_date.to_date)
      spp3 = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day, price_group: @price_group)
      expect(ServicePricePolicy.current_date(@service)).to eq(spp3.start_date.to_date)
    end

    it "returns the date for upcoming policies" do
      spp = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day, price_group: @price_group)
      spp2 = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day + 7.days, price_group: @price_group)
      spp3 = create(:service_price_policy, product: @service, start_date: Time.current.beginning_of_day + 14.days, price_group: @price_group)

      expect(ServicePricePolicy.next_date(@service)).to eq(spp2.start_date.to_date)
      next_dates = ServicePricePolicy.next_dates(@service)
      expect(next_dates.length).to eq(2)
      expect(next_dates.include?(spp2.start_date.to_date)).to be true
      expect(next_dates.include?(spp3.start_date.to_date)).to be true
    end
  end
end
