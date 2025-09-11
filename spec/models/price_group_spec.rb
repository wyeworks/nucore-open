# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriceGroup do

  let(:facility) { FactoryBot.create(:facility) }
  let(:price_group) { FactoryBot.create(:price_group, facility: facility) }

  before :each do
    @facility = facility
    @price_group = price_group
  end

  it "is valid using the factory" do
    expect(price_group).to be_valid
  end

  it "requires name" do
    is_expected.to validate_presence_of(:name)
  end

  it "requires unique name within a facility" do
    price_group2 = build(:price_group, name: price_group.name, facility: facility)
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present
  end

  it "requires the unique name case-insensitively" do
    price_group2 = build(:price_group, name: price_group.name.upcase, facility: facility)
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present

    price_group2.name.downcase!
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present
  end

  context "can_purchase?" do

    before :each do
      @facility_account = FactoryBot.create(:facility_account, facility: @facility)
      @product = FactoryBot.create(:item, facility: @facility, facility_account: @facility_account)
    end

    it "should not be able to purchase product" do
      expect(@price_group).not_to be_can_purchase @product
    end

    it "should be able to purchase product" do
      PriceGroupProduct.create!(price_group: @price_group, product: @product)
      expect(@price_group).to be_can_purchase @product
    end

  end

  describe "to_log_s" do
    it "should be loggable with account price groups" do
      account = create(:setup_account)
      account_price_group_member = create(:account_price_group_member, price_group: @price_group, account: account)
      expect(account_price_group_member.to_log_s).to include(account.to_s)
    end

    it "should be loggable with user price groups" do
      user = create(:user)
      account_price_group_member = create(:user_price_group_member, price_group: @price_group, user: user)
      expect(account_price_group_member.to_log_s).to include(user.to_s)
    end
  end

  describe "can_delete?" do
    it "should not be deletable if global" do
      @global_price_group = FactoryBot.build(:price_group, facility: nil, global: true)
      @global_price_group.save
      expect(@global_price_group).to be_persisted
      expect(@global_price_group).to be_global
      expect(@global_price_group).not_to be_can_delete
      @global_price_group.destroy
      # lambda { @global_price_group.destroy }.should raise_error ActiveRecord::DeleteRestrictionError
      expect(@global_price_group).not_to be_destroyed
    end

    it "should be deletable if no price policies" do
      expect(@price_group).to be_can_delete
      @price_group.destroy
      expect { PriceGroup.find(@price_group.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(PriceGroup.with_deleted.find(@price_group.id)).to be_present
    end

    it "should be able to delete a price group with price group members" do
      user = create(:user)
      user_price_group_member = create(:user_price_group_member, price_group: @price_group, user: user)
      @price_group.destroy
      expect { PriceGroup.find(@price_group.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(PriceGroup.with_deleted.find(@price_group.id)).to be_present
    end

    it "should be able to delete a price group with price group accounts" do
      account = create(:setup_account)
      account_price_group_member = create(:account_price_group_member, price_group: @price_group, account: account)
      @price_group.destroy
      expect { PriceGroup.find(@price_group.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(PriceGroup.with_deleted.find(@price_group.id)).to be_present
    end

    context "with price policy" do
      before :each do
        @facility_account = FactoryBot.create(:facility_account, facility: @facility)
        @item = @facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))
        @price_policy = @item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group: @price_group))
      end

      it "should be deletable if no orders on policy" do
        expect(@price_group).to be_can_delete
        @price_group.destroy
        expect { PriceGroup.find(@price_group.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(PriceGroup.with_deleted.find(@price_group.id)).to be_present
        expect(PricePolicy.find_by(id: @price_policy.id)).to be_blank # It destroys the associated price policy
      end

      it "should not be deletable if there are orders on a policy" do
        @user = FactoryBot.create(:user)
        @order = FactoryBot.create(:order, user: @user, created_by: @user.id)
        @order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail, product: @item, price_policy: @price_policy))
        expect(@order_detail.reload.price_policy).to eq(@price_policy)
        expect(@price_group).not_to be_can_delete
        expect { @price_group.destroy }.to raise_error ActiveRecord::DeleteRestrictionError
        expect(@price_group).not_to be_destroyed
      end
    end
  end

  describe "scoped_name" do
    subject { price_group.name_scoped }

    context "when it's global" do
      before { price_group.update(facility: nil) }

      it { is_expected.to eq price_group.name }
    end

    context "when it's not global" do
      before { price_group.update(facility:) }

      it { is_expected.to include(price_group.name) }
      it { is_expected.to include(facility.name) }
    end
  end
end
