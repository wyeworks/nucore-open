# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriceGroup do

  let(:facility) { create(:facility) }
  let(:price_group) { create(:price_group, facility:) }

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
    price_group2 = build(:price_group, name: price_group.name, facility:)
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present
  end

  it "requires the unique name case-insensitively" do
    price_group2 = build(:price_group, name: price_group.name.upcase, facility:)
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present

    price_group2.name.downcase!
    expect(price_group2).not_to be_valid
    expect(price_group2.errors[:name]).to be_present
  end

  context "can_purchase?" do

    before :each do
      @facility_account = create(:facility_account, facility: @facility)
      @product = create(:item, facility: @facility, facility_account: @facility_account)
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

  describe "external?" do
    context "when is_internal is false" do
      subject { build(:price_group, is_internal: false) }

      it { is_expected.to be_external }
    end

    context "when is_internal is true" do
      subject { build(:price_group, is_internal: true) }

      it { is_expected.not_to be_external }
    end
  end

  describe "external_subsidy?", feature_setting: { external_price_group_subsidies: true } do
    let(:external_base) { create(:price_group, :global_external) }

    context "when external with a parent" do
      subject { build(:price_group, facility:, is_internal: false, parent_price_group: external_base) }

      it { is_expected.to be_external_subsidy }
    end

    context "when external without a parent" do
      subject { build(:price_group, facility:, is_internal: false, parent_price_group: nil) }

      it { is_expected.not_to be_external_subsidy }
    end

    context "when internal with a parent" do
      subject { build(:price_group, facility:, is_internal: true, parent_price_group: external_base) }

      it { is_expected.not_to be_external_subsidy }
    end
  end

  describe "shows_adjustment_input?" do
    context "for non-master internal groups" do
      subject { build(:price_group, is_internal: true, display_order: 2) }

      it { is_expected.to be_shows_adjustment_input }
    end

    context "for master internal (display_order 1)" do
      subject { build(:price_group, is_internal: true, display_order: 1) }

      it { is_expected.not_to be_shows_adjustment_input }
    end

    context "for external subsidy with feature enabled", feature_setting: { external_price_group_subsidies: true } do
      let(:external_base) { create(:price_group, :global_external) }
      subject { build(:price_group, facility:, is_internal: false, parent_price_group: external_base) }

      it { is_expected.to be_shows_adjustment_input }
    end

    context "for external subsidy with feature disabled", feature_setting: { external_price_group_subsidies: false } do
      let(:external_base) { create(:price_group, :global_external) }
      subject { build(:price_group, facility:, is_internal: false, parent_price_group: external_base) }

      it { is_expected.not_to be_shows_adjustment_input }
    end
  end

  describe ".available_parent_groups", feature_setting: { external_price_group_subsidies: true } do
    let!(:external_rate_one) { create(:price_group, :global_external, name: "External Rate 1") }
    let!(:external_rate_two) { create(:price_group, :global_external, name: "External Rate 2") }
    let!(:internal_base) { PriceGroup.base }
    let!(:hidden_external) { create(:price_group, :global_external, name: "Hidden External", is_hidden: true) }

    it "returns only visible global external groups without parents" do
      available = PriceGroup.available_parent_groups(facility)
      expect(available).to include(external_rate_one, external_rate_two)
      expect(available).not_to include(internal_base)
      expect(available).not_to include(hidden_external)
    end
  end

  describe ".ordered_with_subsidies", feature_setting: { external_price_group_subsidies: true } do
    let!(:internal_group) { create(:price_group, facility:, is_internal: true, name: "Internal Group") }
    let!(:external_base) { create(:price_group, :global_external, name: "External Base") }
    let!(:subsidy_one) { create(:price_group, facility:, is_internal: false, parent_price_group: external_base, name: "Subsidy 1") }
    let!(:subsidy_two) { create(:price_group, facility:, is_internal: false, parent_price_group: external_base, name: "Subsidy 2") }

    it "orders groups with subsidies immediately after their parent" do
      groups = [internal_group, external_base, subsidy_one, subsidy_two]
      ordered = PriceGroup.ordered_with_subsidies(groups)

      external_base_index = ordered.index(external_base)
      subsidy_one_index = ordered.index(subsidy_one)
      subsidy_two_index = ordered.index(subsidy_two)

      expect(subsidy_one_index).to be > external_base_index
      expect(subsidy_two_index).to be > external_base_index
    end

    it "places internal groups before external groups" do
      groups = [external_base, internal_group, subsidy_one]
      ordered = PriceGroup.ordered_with_subsidies(groups)

      expect(ordered.index(internal_group)).to be < ordered.index(external_base)
    end
  end

  describe ".ordered_with_subsidies with feature disabled", feature_setting: { external_price_group_subsidies: false } do
    it "returns groups unchanged when feature is disabled" do
      groups = [price_group]
      expect(PriceGroup.ordered_with_subsidies(groups)).to eq(groups)
    end
  end

  describe "can_delete?" do
    it "should not be deletable if global" do
      @global_price_group = build(:price_group, facility: nil, global: true)
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
        @facility_account = create(:facility_account, facility: @facility)
        @item = @facility.items.create(attributes_for(:item, facility_account_id: @facility_account.id))
        @price_policy = @item.item_price_policies.create(attributes_for(:item_price_policy, price_group: @price_group))
      end

      it "should be deletable if no orders on policy" do
        expect(@price_group).to be_can_delete
        @price_group.destroy
        expect { PriceGroup.find(@price_group.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(PriceGroup.with_deleted.find(@price_group.id)).to be_present
        expect(PricePolicy.find_by(id: @price_policy.id)).to be_blank # It destroys the associated price policy
      end

      it "should not be deletable if there are orders on a policy" do
        @user = create(:user)
        @order = create(:order, user: @user, created_by: @user.id)
        @order_detail = @order.order_details.create(attributes_for(:order_detail, product: @item, price_policy: @price_policy))
        expect(@order_detail.reload.price_policy).to eq(@price_policy)
        expect(@price_group).not_to be_can_delete
        expect { @price_group.destroy }.to raise_error ActiveRecord::DeleteRestrictionError
        expect(@price_group).not_to be_destroyed
      end
    end
  end

end
