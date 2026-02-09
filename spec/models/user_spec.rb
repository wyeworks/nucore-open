# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject(:user) { create(:user, :netid) }
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:item, facility: facility) }
  let(:price_group) { create(:price_group, facility: facility) }
  let(:price_policy) { create(:item_price_policy, product: item, price_group: price_group) }

  it { is_expected.to accept_nested_attributes_for(:account_users) }

  it "validates uniqueness of username" do
    # we need at least 1 user to test validations
    is_expected.to validate_uniqueness_of(:username).case_insensitive
  end

  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  context "when the created username is mixed-case" do
    subject(:user) { create(:user, username: "AnEmail@example.org") }

    it "lowercases the username" do
      expect(user.reload.username).to eq("anemail@example.org")
    end
  end

  it { is_expected.to have_many(:notifications) }

  it { is_expected.to be_valid }

  context "when user has email address with apostrophe" do
    subject(:user) { build(:user, email: "o'niel@example.com") }

    it { is_expected.to be_valid }
  end

  describe "#create_default_price_group!", feature_setting: { user_based_price_groups: true } do
    before do
      expect(User).to receive(:default_price_group_finder).and_return(Users::DefaultPriceGroupSelector.new)
    end

    # factory uses create_default_price_group!
    it "default has the base price group" do
      expect(user.price_groups).to eq [PriceGroup.base]
    end

    it "external user has external price group" do
      external_user = FactoryBot.create(:user, :external)
      expect(external_user.price_groups).to eq [PriceGroup.external]
    end
  end

  describe "price groups", feature_setting: { user_based_price_groups: true } do

    it "is a member of any explicitly mapped price groups" do
      pg = FactoryBot.create(:price_group, facility: facility)
      UserPriceGroupMember.create(user: user, price_group: pg)
      expect(user.price_groups.include?(pg)).to eq(true)
    end

    it "belongs to price groups of accounts" do
      cc = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user))
      pg = FactoryBot.create(:price_group, facility: facility)
      AccountPriceGroupMember.create(account: cc, price_group: pg)
      expect(user.account_price_groups.include?(pg)).to be true
    end

    it "belongs to price groups of the account owner" do
      owner = create(:user)
      cc = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: owner))
      pg = FactoryBot.create(:price_group, facility: facility)
      UserPriceGroupMember.create(user: owner, price_group: pg)

      cc.account_users.create(user: user, created_by: owner.id, user_role: "Purchaser")

      expect(user.account_price_groups.include?(pg)).to be true
    end
  end

  it { is_expected.not_to be_authenticated_locally }

  it "can be locally authenticated as a netid user (email != username)" do
    user.password = "Passw0rd!!"
    assert user.save
    expect(user).to be_authenticated_locally
  end

  it "aliases username to login" do
    expect(user).to be_respond_to(:login)
    expect(user.username).to eq(user.login)
  end

  it { is_expected.to be_respond_to(:ldap_attributes) }

  describe ".with_global_roles" do
    subject(:users_with_global_roles) { described_class.with_global_roles }
    let!(:unprivileged_users) { create_list(:user, 2) }

    context "when no users have global roles" do
      it { is_expected.to be_empty }
    end

    context "when users have the account manager role" do
      let!(:privileged_users) { create_list(:user, 2, :account_manager) }

      it { is_expected.to match_array(privileged_users) }
    end

    context "when users have the global billing administrator role", feature_setting: { global_billing_administrator: true } do
      let!(:privileged_users) { create_list(:user, 2, :global_billing_administrator) }

      it { is_expected.to match_array(privileged_users) }
    end

    context "when users have the global administrator role" do
      let!(:privileged_users) { create_list(:user, 2, :administrator) }

      it { is_expected.to match_array(privileged_users) }
    end
  end

  describe "#accounts_for_product" do
    let(:account) { create(:nufs_account, account_users_attributes: [attributes_for(:account_user, user: user)]) }

    before(:each) do
      price_policy.reload.restrict_purchase = false
      create(:account_price_group_member, account: account, price_group: price_group)
    end

    it "does not have an account because there is no price group" do
      AccountPriceGroupMember.where(account_id: account.id, price_group_id: price_group.id).first.destroy
      expect(user.accounts_for_product(item)).to be_empty
    end

    it "has no account" do
      define_open_account(item.account, account.account_number)
      accts = user.accounts_for_product(item)
      expect(accts.size).to eq(1)
      expect(accts.first).to eq(account)
    end
  end

  describe "#approval_dates_by_product" do
    context "when the user is on the access list for a product" do
      let(:product) { create(:instrument_requiring_approval) }

      before { create(:product_user, product: product, user: user) }

      it { expect(user.approval_dates_by_product).to have_key(product.id) }
    end

    context "when the user is not on any access lists for products" do
      it { expect(user.approval_dates_by_product).to eq({}) }
    end
  end

  describe "#cart" do
    let(:order) { user.orders.create(attributes_for(:order, created_by: user.id, facility: facility)) }

    before(:each) do
      create(:user_price_group_member, user: user, price_group: price_group)
      price_policy.reload.restrict_purchase = false
      order.order_details.create(attributes_for(:order_detail, product_id: item.id))
    end

    it "returns the order when given created_by user" do
      expect(user.cart(user)).to eq(order)
    end

    it "returns the order when not given a created_by user" do
      expect(user.cart).to eq(order)
    end

    context "when the order is empty (has no order_details)" do
      before { order.order_details.destroy_all }

      it "returns the existing unordered order" do
        expect(user.cart(user).reload).to eq(order)
      end
    end

    it "returns a new order when given a created_by user" do
      new_order = user.cart(user, false)
      expect(new_order).not_to eq(order)
      expect(new_order.user).to eq(user)
      expect(new_order.created_by).to eq(user.id)
    end

    it "returns a new order when created_by user is nil" do
      new_order = user.cart(nil, false)
      expect(new_order).not_to eq(order)
      expect(new_order.user).to eq(user)
      expect(new_order.created_by).to eq(user.id)
    end
  end

  describe ".find_users_by_facility" do
    let!(:facility_director) { create(:user, :facility_director, facility: facility) }
    let!(:staff) { create(:user, :staff, facility: facility) }
    let!(:normal_user) { create(:user) }
    let!(:other_facilitly_director) { create(:user, :facility_director, facility: create(:facility)) }
    let!(:facility_admin_and_director) do
      create(:user, :facility_director, :facility_administrator, facility: facility)
    end

    it "finds just the users for that facility" do
      expect(described_class.find_users_by_facility(facility)).to contain_exactly(facility_director, staff, facility_admin_and_director)
    end
  end

  describe "#operable_facilities" do
    let(:user) { create(:user) }
    let(:facility1) { create(:facility) }
    let(:facility2) { create(:facility) }

    context "when user has only facility roles" do
      before do
        UserRole.grant(user, UserRole::FACILITY_STAFF, facility1)
      end

      it "returns facilities from roles" do
        expect(user.operable_facilities).to contain_exactly(facility1)
      end
    end

    context "when user has only granular permissions" do
      before do
        create(:facility_user_permission, user:, facility: facility2, assign_permissions: true)
      end

      it "returns facilities from permissions" do
        expect(user.operable_facilities).to contain_exactly(facility2)
      end
    end

    context "when user has both roles and permissions on different facilities" do
      before do
        UserRole.grant(user, UserRole::FACILITY_STAFF, facility1)
        create(:facility_user_permission, user:, facility: facility2, assign_permissions: true)
      end

      it "returns both facilities without duplicates" do
        expect(user.operable_facilities).to contain_exactly(facility1, facility2)
      end
    end

    context "when user has both role and permission on the same facility" do
      before do
        UserRole.grant(user, UserRole::FACILITY_STAFF, facility1)
        create(:facility_user_permission, user:, facility: facility1, product_management: true)
      end

      it "returns the facility once" do
        expect(user.operable_facilities).to contain_exactly(facility1)
      end
    end

    context "when user is an administrator" do
      let(:user) { create(:user, :administrator) }

      before do
        facility1
        facility2
      end

      it "returns all facilities" do
        expect(user.operable_facilities).to include(facility1, facility2)
      end
    end
  end
end
