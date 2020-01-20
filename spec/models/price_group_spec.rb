# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriceGroup do

  let(:facility) { @facility }

  before :each do
    @facility = FactoryBot.create(:facility)
    @price_group = FactoryBot.create(:price_group, facility: facility)
  end

  it "should create using factory" do
    expect(@price_group).to be_valid
  end

  it "should require name" do
    is_expected.to validate_presence_of(:name)
  end

  it "should require unique name within a facility" do
    @price_group2 = @facility.price_groups.build(FactoryBot.attributes_for(:price_group).update(name: @price_group.name))
    expect(@price_group2).not_to be_valid
    expect(@price_group2.errors[:name]).not_to be_nil
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

  describe "can_delete?" do
    it "should not be deletable if global" do
      @global_price_group = FactoryBot.build(:price_group, facility: nil)
      @global_price_group.save(validate: false)
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
      expect(@price_group).to be_destroyed
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
        expect(@price_group).to be_destroyed
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

  # global price groups are special cases; we don't test them here because price groups are required to have facilities
  # it "should not be deletable if its a global price group" do
  #   @global_price_group = FactoryBot.create(:price_group)
  #   @global_price_group.should be_valid
  #   @global_price_group.destroy.should == false
  # end

end
