# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricePolicy do
  before(:each) do
    allow(Settings.financial).to receive(:fiscal_year_begins).and_return("10-01")
  end

  let(:facility) { @facility }

  before :each do
    @facility = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @facility)
    @price_group = FactoryBot.create(:price_group, facility: facility)
    @item = FactoryBot.create(:item, facility: @facility, facility_account: @facility_account)
  end

  context "current and newest" do
    let!(:price_policy) do
      FactoryBot.create(
        :instrument_price_policy,
        start_date: Time.zone.now,
        expire_date: Time.zone.now + 1.day,
      )
    end
    let!(:overlapping_price_policy) do
      FactoryBot.create(
        :instrument_price_policy,
        start_date: 1.day.ago.beginning_of_day,
        product: price_policy.product,
        price_group: price_policy.price_group,
      )
    end

    it "has two overlapping policies" do
      policies = price_policy.product.price_policies
      expect(policies.current.count).to be > policies.current_and_newest.count
    end
  end

  context "expire date" do
    let(:start_date) { 1.year.from_now.change(month: 5, day: 5) }

    it "should not allow an expire date the same as start date" do
      pp = ItemPricePolicy.new(
        FactoryBot.attributes_for(:item_price_policy,
                                  price_group_id: @price_group.id,
                                  product_id: @item.id,
                                  start_date: start_date,
                                  expire_date: start_date),
      )

      expect(pp).not_to be_valid
      expect(pp.errors[:expire_date]).to be_present
    end

    it "should not allow an expire date after a generated date" do
      pp = ItemPricePolicy.new(
        FactoryBot.attributes_for(:item_price_policy,
                                  price_group_id: @price_group.id,
                                  product_id: @item.id,
                                  start_date: start_date,
                                  expire_date: PricePolicy.generate_expire_date(start_date) + 1.month),
      )
      expect(pp).not_to be_valid
      expect(pp.errors[:expire_date]).to be_present
    end

    it "should not set default expire_date if one is given" do
      expire_date = start_date + 3.months
      pp = FactoryBot.create(:item_price_policy,
                             price_group_id: @price_group.id,
                             product_id: @item.id, start_date: start_date,
                             expire_date: expire_date
                            )
      expect(pp.expire_date).not_to be_nil
      expect(pp.expire_date).to eq(expire_date)
    end

    it "should not be expired" do
      expire_date = start_date + 3.months
      pp = FactoryBot.create(:item_price_policy,
                             price_group_id: @price_group.id,
                             product_id: @item.id,
                             start_date: start_date,
                             expire_date: expire_date)
      expect(pp).not_to be_expired
    end

    it "should be expired when in the past" do
      start_date = Time.zone.parse("2000-5-5")
      expire_date = start_date + 1.month
      pp = FactoryBot.create(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id, start_date: start_date, expire_date: expire_date)
      expect(pp).to be_expired
    end

  end

  context "restrict purchase" do

    before :each do
      @pp = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group)
      # @pgp=FactoryBot.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
    end

    it "should not restrict purchase" do
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should restrict purchase" do
      @pp.update(can_purchase: false)
      expect(@pp.restrict_purchase).to eq(true)
    end

    it "should restrict purchase" do
      @pp.restrict_purchase = true
      expect(@pp.restrict_purchase).to be true
      expect(@pp.can_purchase).to be false
    end

    it "should alias #restrict with query method" do
      expect(@pp).to be_respond_to :restrict_purchase?
      expect(@pp.restrict_purchase).to eq(@pp.restrict_purchase?)
    end

    it "should return false when no price group present" do
      @pp.price_group = nil
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should return false when no item present" do
      @pp.product = nil
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should raise on bad input" do
      expect { @pp.restrict_purchase = 44 }.to raise_error ArgumentError
    end

    it "should destroy PriceGroupProduct when restricted" do
      @pp.restrict_purchase = true
      should_be_destroyed @pgp
    end
  end

  context "truncate old policies" do
    before :each do
      @user     = FactoryBot.create(:user)
      @account  = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @price_group = FactoryBot.create(:price_group, facility: @facility)
      @item2 = @facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))
    end
    it "should truncate the old policy" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)
      travel_to_and_return(@today) do
        @pp = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today.beginning_of_day, expire_date: @today + 30.days)
        @pp2 = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today + 2.days, expire_date: @today + 30.days)
        expect(@pp.reload.start_date).to eq(@today.beginning_of_day)
        expect(@pp.expire_date).to be < (@today + 1.day).end_of_day
        expect(@pp2.reload.start_date).to eq(@today + 2.days)
        expect(@pp2.expire_date).to eq(@today + 30.days)
      end
    end

    it "should not truncate any other policies" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)

      travel_to_and_return(@today) do
        @pp = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today.beginning_of_day, expire_date: @today + 30.days)
        @pp3 = FactoryBot.create(:item_price_policy, product: @item2, price_group: @price_group, start_date: @today, expire_date: @today + 30.days)
        @pp2 = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today + 2.days, expire_date: @today + 30.days)
        expect(@pp.reload.start_date).to eq(@today.beginning_of_day)
        expect(@pp.expire_date).to be < (@today + 1.day).end_of_day
        expect(@pp2.reload.start_date).to eq(@today + 2.days)
        expect(@pp2.expire_date).to eq(@today + 30.days)

        expect(@pp3.reload.start_date).to eq(@today)
        expect(@pp3.expire_date).to eq(@today + 30.days)
      end
    end

    context "should define abstract methods" do

      before :each do
        @sp = PricePolicy.new
      end

      it "should abstract #calculate_cost_and_subsidy" do
        expect(@sp).to be_respond_to(:calculate_cost_and_subsidy)
        expect { @sp.calculate_cost_and_subsidy }.to raise_error RuntimeError
      end

      it "should abstract #estimate_cost_and_subsidy" do
        expect(@sp).to be_respond_to(:estimate_cost_and_subsidy)
        expect { @sp.estimate_cost_and_subsidy }.to raise_error RuntimeError
      end

    end

    context "order assignment" do

      before :each do
        @user     = FactoryBot.create(:user)
        @account  = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
        @order    = @user.orders.create(FactoryBot.attributes_for(:order, created_by: @user.id))
        @order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
        @price_group = FactoryBot.create(:price_group, facility: @facility)
        create(:account_price_group_member, account: @account, price_group: @price_group)
        FactoryBot.create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
        @pp = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group)
      end

      it "should not be assigned" do
        expect(@pp).not_to be_assigned_to_order
      end

      it "should be assigned" do
        @order_detail.reload
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        expect(@pp).to be_assigned_to_order
      end

    end

  end

  describe "unit_net_cost" do
    let(:attrs) do
      {
        unit_cost: 20.0,
        unit_subsidy: 1.0,
        usage_rate: 8.0,
        usage_subsidy: 3.0,
      }
    end

    it "returns nil for base class" do
      instance = PricePolicy.new(attrs)

      expect(instance.unit_net_cost).to be(nil)
    end

    it "returns usage for instrument policy" do
      instance = InstrumentPricePolicy.new(attrs)

      expect(instance.unit_net_cost).to be_within(1e-5).of(5.0)
    end

    it "returns unit for item policy" do
      instance = ItemPricePolicy.new(attrs)

      expect(instance.unit_net_cost).to be_within(1e-5).of(19.0)
    end
  end

  describe "note" do
    context "when the required note feature is enabled", feature_setting: { price_policy_requires_note: true } do
      it "requires the note" do
        note = described_class.new(note: "")
        expect(note).to be_invalid
        expect(note.errors).to be_added(:note, :blank)
        expect(note.errors).not_to be_added(:note, :too_short, count: 10)
      end

      it "requires the note be long enough" do
        note = described_class.new(note: "a")
        expect(note).to be_invalid
        expect(note.errors).not_to be_added(:note, :blank)
        expect(note.errors).to be_added(:note, :too_short, count: 10)
      end

      it "is fine when it is present and long enough" do
        note = described_class.new(note: "12345678910")
        note.valid?
        expect(note.errors).not_to include(:note)
      end

      it "requires it be short enough" do
        note = described_class.new(note: "x" * 257)
        expect(note).to be_invalid
        expect(note.errors).to be_added(:note, :too_long, count: 256)
      end

      it "does not require the note for existing records" do
        price_policy = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group)
        price_policy.note = ""
        expect(price_policy).to be_valid
      end
    end

    context "when the required note feature is disabled", feature_setting: { price_policy_requires_note: false } do
      it "is fine with a blank value" do
        note = described_class.new(note: "")
        note.valid?
        expect(note.errors).not_to include(:note)
      end

      it "requires it be short enough" do
        note = described_class.new(note: "x" * 257)
        expect(note).to be_invalid
        expect(note.errors).to be_added(:note, :too_long, count: 256)
      end
    end
  end

end
