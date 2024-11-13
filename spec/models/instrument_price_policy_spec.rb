# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentPricePolicy do

  subject(:policy) { build :instrument_price_policy }

  %w(minimum_cost cancellation_cost).each do |attr|
    it { is_expected.to validate_numericality_of(attr.to_sym).is_greater_than_or_equal_to 0 }
    it { is_expected.to allow_value(nil).for attr.to_sym }
  end

  it { is_expected.to validate_inclusion_of(:charge_for).in_array described_class::CHARGE_FOR.values }

  it "converts the given hourly usage_rate to a per minute rate" do
    policy.usage_rate = 10
    expect(policy.usage_rate.round(4)).to eq (10 / 60.0).round(4)
  end

  it "converts the given hourly usage_subsidy to a per minute rate" do
    policy.usage_subsidy = 10
    expect(policy.usage_subsidy.round(4)).to eq (10 / 60.0).round(4)
  end

  it { is_expected.to allow_value(nil).for :usage_subsidy }

  it "ensures that usage subsidy is greater than 0" do
    policy.usage_subsidy = -1
    expect(policy).to_not be_valid
    expect(policy.errors[:usage_subsidy]).to be_present
  end

  describe "usage rate validations" do
    it "ensures that usage rate is greater than 0" do
      policy.usage_rate = -1
      expect(policy).to_not be_valid
      expect(policy.errors[:usage_rate]).to be_present
    end

    it "validates presence of usage rate if purchase is not restricted" do
      allow(policy).to receive(:restrict_purchase?).and_return false
      is_expected.to validate_presence_of :usage_rate
    end

    it "does not validate presence of usage rate if purchase is restricted" do
      allow(policy).to receive(:restrict_purchase?).and_return true
      is_expected.not_to validate_presence_of :usage_rate
    end
  end

  describe "validation using #subsidy_less_than_rate?" do
    it "gives an error if usage_subsidy > usage_rate" do
      expect(policy).to be_valid
      policy.usage_subsidy = 15
      policy.usage_rate = 5
      expect(policy).to_not be_valid
      expect(policy.errors[:usage_subsidy]).to be_present
    end

    it "does not give an error if usage_subsidy < usage_rate" do
      expect(policy).to be_valid
      policy.usage_subsidy = 15
      policy.usage_rate = 25
      expect(policy).to be_valid
    end
  end

  describe "before save" do
    it "sets the usage subsidy to 0 before save if there is a usage_rate" do
      expect(policy.usage_rate).to be_present
      policy.usage_subsidy = nil
      expect(policy.save).to be true
      expect(policy.reload.usage_subsidy).to eq 0
    end

    it "does not set the usage subsidy before save if there is a usage_rate and it is already set" do
      policy.usage_rate = 50
      policy.usage_subsidy = 5
      expect(policy.save).to be true
      expect(policy.reload.usage_subsidy).to eq (5 / 60.0).round(8)
    end

    it "does not set the usage subsidy before save if there is no usage_rate" do
      allow(policy).to receive(:restrict_purchase?).and_return true
      policy.usage_rate = nil
      policy.usage_subsidy = nil
      expect(policy.save).to be true
      expect(policy.reload.usage_subsidy).to be_nil
    end
  end

  describe "after create" do
    it "creates a PriceGroupProduct with default reservation window if one does not exist" do
      pgp = PriceGroupProduct.find_by(price_group_id: policy.price_group.id, product_id: policy.product.id)
      expect(pgp).to be_nil
      expect(policy.save).to be true
      pgp = PriceGroupProduct.find_by(price_group_id: policy.price_group.id, product_id: policy.product.id)
      expect(pgp.reservation_window).to eq PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    end

    it "does not create a PriceGroupProduct with default reservation window if one exists" do
      PriceGroupProduct.create(
        price_group: policy.price_group,
        product: policy.product,
        reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW,
      )

      expect(PriceGroupProduct).to_not receive :create
      expect(policy.save).to be true
    end
  end

  it "returns the date for upcoming policies" do
    instrument = policy.product
    price_group = policy.price_group
    create :instrument_price_policy, start_date: Time.current.beginning_of_day, price_group: price_group, product: instrument
    ipp2 = create :instrument_price_policy, start_date: Time.current.beginning_of_day + 7.days, price_group: price_group, product: instrument
    ipp3 = create :instrument_price_policy, start_date: Time.current.beginning_of_day + 14.days, price_group: price_group, product: instrument

    expect(described_class.next_date(instrument).to_date).to eq ipp2.start_date.to_date
    next_dates = described_class.next_dates instrument

    expect(next_dates.size).to eq 2
    expect(next_dates).to include ipp2.start_date.to_date
    expect(next_dates).to include ipp3.start_date.to_date
  end

  describe "#reservation_window" do
    it "returns 0 if there is no PriceGroupProduct" do
      expect(policy.reservation_window).to eq 0
    end

    it "returns the reservation window from the after created PriceGroupProduct" do
      expect(policy.save).to be true
      pgp = PriceGroupProduct.find_by(price_group_id: policy.price_group.id, product_id: policy.product.id)
      expect(policy.reservation_window).to eq pgp.reservation_window
    end
  end

  describe "#has_subsidy?" do
    it "has a subsidy if the attribute is greater than 0" do
      policy.usage_subsidy = 9.0
      expect(policy).to have_subsidy
    end

    it "does not have a subsidy if the attribute is 0" do
      policy.usage_subsidy = 0
      expect(policy).to_not have_subsidy
    end

    it "does not have a subsidy if the attribute does not exist" do
      policy.usage_subsidy = nil
      expect(policy).to_not have_subsidy
    end
  end

  describe "hourly rates" do
    it "gives the hourly version of the usage rate" do
      expect(policy.hourly_usage_rate).to eq policy.usage_rate * 60
    end

    it "gives the hourly version of the usage subsidy" do
      expect(policy.hourly_usage_subsidy).to eq policy.usage_subsidy * 60
    end

    it "returns nil if usage rate is nil" do
      policy.usage_rate = nil
      expect(policy.hourly_usage_rate).to be_nil
    end

    it "returns nil if usage subsidy is nil" do
      policy.usage_subsidy = nil
      expect(policy.hourly_usage_subsidy).to be_nil
    end
  end

  describe "daily rates" do
    let(:instrument) do
      build :instrument, pricing_mode: Instrument::Pricing::SCHEDULE_DAILY
    end

    let(:policy) { build :instrument_price_policy, product: instrument }

    shared_examples "validates policy field" do |field_name|
      before { policy.valid? }

      it { expect(policy).to_not be_valid }
      it { expect(policy.errors).to include(field_name) }
    end

    describe "with negative usage_rate_daily value" do
      before { policy.usage_rate_daily = -1 }

      it_behaves_like "validates policy field", :usage_rate_daily
    end

    describe "with negative usage_subsidy_daily value" do
      before { policy.usage_subsidy_daily = -1 }

      it_behaves_like "validates policy field", :usage_subsidy_daily
    end

    describe "with negative usage_rate_daily value" do
      before { policy.usage_rate_daily = -1 }

      it_behaves_like "validates policy field", :usage_rate_daily
    end

    describe "with missing usage_rate_daily value" do
      before { policy.usage_rate_daily = nil }

      it_behaves_like "validates policy field", :usage_rate_daily
    end

    describe "when subsidy is greater than rate" do
      before do
        policy.usage_rate_daily = 9.9
        policy.usage_subsidy_daily = 10
      end

      it_behaves_like "validates policy field", :usage_subsidy_daily
    end

    it "does not save usage_rate if usage_rate_daily is present" do
      policy.usage_rate_daily = 10
      policy.usage_rate = 10
      policy.usage_subsidy = 10

      expect(policy).to be_valid
      expect(policy.usage_rate).to be_nil
      expect(policy.usage_subsidy).to be_nil
    end

    it "does not require usage_rate when instrument is scheduled daily" do
      policy.usage_rate_daily = 10
      policy.usage_rate = nil

      expect(policy).to be_valid
    end

    it "does not require usage_rate_daily if instrument is not scheduled daily" do
      instrument.pricing_mode = Instrument::Pricing::DURATION

      expect(policy).to be_valid
    end
  end
end
