# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account do
  let(:account) { create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user)) }
  let(:facility) { facility_a }
  let(:facility_a) { create(:facility) }
  let(:facility_b) { create(:facility) }
  let(:user) { create(:user) }

  it_should_behave_like "an Account"

  describe ".with_orders_for_facility" do
    subject { described_class.with_orders_for_facility(facility) }
    let(:product_a) { create(:setup_item, :with_facility_account, facility: facility_a) }
    let(:product_b) { create(:setup_item, :with_facility_account, facility: facility_b) }

    context "when there are no orders" do
      context "when querying a single facility" do
        it { is_expected.to be_empty }
      end

      context "when querying across all facilities" do
        let(:facility) { Facility.cross_facility }

        it { is_expected.to be_empty }
      end
    end

    context "when there are fewer than 1000 accounts" do
      before(:each) do
        create_list(:nufs_account, 3, :with_order, product: product_a)
        create_list(:nufs_account, 3, :with_order, product: product_b)
      end

      context "when querying a single facility" do
        it { is_expected.to have(3).items }
        it { is_expected.to all be_a(NufsAccount) }
      end

      context "when querying across all facilities" do
        let(:facility) { Facility.cross_facility }

        it { is_expected.to have(6).items }
        it { is_expected.to all be_a(NufsAccount) }
      end
    end

    # SLOW
    # context "when there are more than 1000 accounts" do
    #   before { create_list(:nufs_account, 1001, :with_order, product: product_a) }
    #   let(:accounts_for_facility_a) { described_class.with_orders_for_facility(facility_a) }
    #   let(:accounts_for_all_facilities) { described_class.with_orders_for_facility(Facility.cross_facility) }

    #   it "queries without error" do
    #     expect(accounts_for_facility_a.count).to eq(1001)
    #     expect(accounts_for_all_facilities.count).to eq(1001)
    #   end
    # end
  end

  describe "#affiliate_to_s" do
    subject { account.affiliate_to_s }

    before do
      account.update_attributes(
        affiliate_id: affiliate.try(:id),
        affiliate_other: affiliate_other,
      )
    end

    context "when it has no affiliate" do
      let(:affiliate) { nil }
      let(:affiliate_other) { nil }

      it { is_expected.to be_blank }
    end

    context "when it has an affiliate" do
      let(:affiliate) { Affiliate.create!(name: "Affiliate") }
      let(:affiliate_other) { nil }

      it { is_expected.to eq("Affiliate") }

      context "and the affiliate is 'Other'" do
        let(:affiliate) { Affiliate.OTHER }
        let(:affiliate_other) { "External" }

        it { is_expected.to eq("Other: External") }
      end

      context "and it has a subaffiliate" do
        before { affiliate.update_attribute(:subaffiliates_enabled, true) }

        let(:affiliate_other) { "Subcategory" }

        it { is_expected.to eq("Affiliate: Subcategory") }
      end
    end
  end

  describe "#owner_user_name" do
    context "when the account has an owner" do
      it { expect(account.owner_user_name).to eq(user.name) }
    end

    context "when the account has no owner" do
      before { account.account_users.each(&:destroy) }

      it { expect(account.owner_user_name).to be_blank }
    end
  end

  context "#unreconciled_total" do
    context "without unreconciled order_details" do
      it "should total 0" do
        expect(account.unreconciled_total(facility)).to eq 0
      end
    end

    context "with unreconciled order_details" do
      let(:order_details) { Array.new(5) { double OrderDetail } }

      context "with estimated totals" do
        before :each do
          order_details.each_with_index do |order_detail, n|
            allow(order_detail).to receive(:cost_estimated?).and_return true
            allow(order_detail).to receive(:estimated_total).and_return(n + 1)
          end
        end

        it "should produce the expected total" do
          expect(account.unreconciled_total(facility, order_details)).to eq(15)
        end
      end

      context "with actual totals" do
        before :each do
          order_details.each_with_index do |order_detail, n|
            allow(order_detail).to receive(:cost_estimated?).and_return false
            allow(order_detail).to receive(:actual_total).and_return(n + 1)
          end
        end

        it "should produce the expected total" do
          expect(account.unreconciled_total(facility, order_details)).to eq(15)
        end
      end
    end
  end

  it "should not create using factory" do
    @user    = FactoryBot.create(:user)
    hash     = Hash[user: @user, created_by: @user.id, user_role: "Owner"]
    @account = create_nufs_account_with_owner :user

    expect(@account.errors[:type]).not_to be_nil
  end

  it "should require account_number" do
    is_expected.to validate_presence_of(:account_number)
  end

  it "should require expires_at" do
    is_expected.to validate_presence_of(:expires_at)
  end

  it { is_expected.to belong_to(:affiliate) }
  it { is_expected.to have_many(:orders) }
  it { is_expected.to have_one(:owner) }
  it { is_expected.to have_many(:account_users) }

  it "should be expired" do
    owner   = FactoryBot.create(:user)
    account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: owner))
    account.expires_at = Time.zone.now
    assert account.save
    expect(account).to be_expired
  end

  it "should validate description <= 50 chars" do
    @user = FactoryBot.create(:user)
    account = Account.new(FactoryBot.attributes_for(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user)))
    account.description = random_string = SecureRandom.hex(51)
    expect(account).not_to be_valid
    expect(account.error_on(:description).size).to eq(1)
  end

  it "should set suspend_at on suspend and unsuspend" do
    @owner   = FactoryBot.create(:user)
    @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @owner))
    expect(@account.suspend).to be(true)
    expect(@account.suspended_at).to be_present
    expect(@account.unsuspend).to be(true)
    expect(@account.suspended_at).to be_nil
  end

  context "account users" do
    it "should find all the accounts a user has access to, default suspended? to false" do
      @user    = FactoryBot.create(:user)
      @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      expect(@account.owner_user).to eq(@user)
      expect(@account.suspended?).to eq(false)
    end

    it "should require an account owner" do
      @account = Account.create
      expect(@account.errors[:base]).to eq(["Must have an account owner"])
    end

    it "autosaves the association to the account owner" do
      user = FactoryBot.create(:user)
      account = FactoryBot.build(:account)
      account_user = account.account_users.build(user: user, user_role: AccountUser::ACCOUNT_OWNER, created_by_user: user)

      expect(account.save).to be_truthy
      expect(account_user).to be_persisted
    end

    it "should find the non-deleted account owner" do
      @user1   = FactoryBot.create(:user)
      @user2   = FactoryBot.create(:user)
      @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user1))

      expect(@account.owner_user).to eq(@user1)
      @account.owner.update_attributes(deleted_at: Time.zone.now, deleted_by: @user1.id)
      @account_user2 = @account.account_users.create(user_id: @user2.id, user_role: "Owner", created_by: @user2.id)
      @account.reload # load fresh account users with update attributes
      expect(@account.owner_user).to eq(@user2)
    end

    it "should find all non-suspended account business admins" do
      @owner   = FactoryBot.create(:user)
      @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @owner))

      @user1   = FactoryBot.create(:user)
      @user2   = FactoryBot.create(:user)
      @account.account_users.create(user_id: @user1.id, user_role: "Business Administrator", created_by: @owner.id)
      @account.account_users.create(user_id: @user2.id, user_role: "Business Administrator", created_by: @owner.id, deleted_at: Time.zone.now, deleted_by: @owner.id)

      expect(@account.business_admin_users).to include @user1
      expect(@account.business_admin_users).not_to include @user2
    end

    it "should find all non-suspended business admins and the owner as notify users" do
      @owner   = FactoryBot.create(:user)
      @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @owner))

      @user1   = FactoryBot.create(:user)
      @user2   = FactoryBot.create(:user)
      @account.account_users.create(user_id: @user1.id, user_role: "Business Administrator", created_by: @owner.id)
      @account.account_users.create(user_id: @user2.id, user_role: "Business Administrator", created_by: @owner.id, deleted_at: Time.zone.now, deleted_by: @owner.id)

      expect(@account.notify_users).to include @owner
      expect(@account.notify_users).to include @user1
      expect(@account.notify_users).not_to include @user2
    end

    it "should verify if a user can purchase using the account" do
      @owner   = FactoryBot.create(:user)
      @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @owner))

      @admin   = FactoryBot.create(:user)
      @user    = FactoryBot.create(:user)
      @account.account_users.create(user_id: @admin.id, user_role: "Business Administrator", created_by: @owner.id)
      @user_au = @account.account_users.create(user_id: @user.id, user_role: "Purchaser", created_by: @owner.id)

      expect(@account.can_be_used_by?(@owner)).to eq(true)
      expect(@account.can_be_used_by?(@admin)).to eq(true)
      expect(@account.can_be_used_by?(@user)).to eq(true)

      @user_au.update_attributes(deleted_at: Time.zone.now, deleted_by: @owner.id)
      expect(@account.can_be_used_by?(@user)).to eq(false)
    end
  end

  context do
    let(:nufs_account) { @nufs_account }

    before(:each) do
      @facility          = FactoryBot.create(:facility)
      @user              = FactoryBot.create(:user)
      @nufs_account      = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @facility_account  = FactoryBot.create(:facility_account, facility: @facility)
      @item              = @facility.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))
      @price_group       = FactoryBot.create(:price_group, facility: @facility)
      @price_group_product = FactoryBot.create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
      @price_policy = FactoryBot.create(:item_price_policy, product: @item, price_group: @price_group)
      @price_group_member = create(:account_price_group_member, account: @nufs_account, price_group: @price_group)
    end

    context "description" do
      it "overrides #to_s and does not include owner" do
        expect(nufs_account.to_s).to include(nufs_account.account_number)
        expect(nufs_account.to_s).to include(nufs_account.description)
        expect(nufs_account.to_s).not_to include(nufs_account.owner_user_name)
      end

      it "overrides #to_s and includes owner" do
        expect(nufs_account.to_s(true)).to include(nufs_account.owner_user_name)
      end
    end

    context "validation against product/user" do
      it "should return nil if all conditions are met for validation" do
        define_open_account(@item.account, @nufs_account.account_number)
        expect(@nufs_account.validate_against_product(@item, @user)).to eq(nil)
      end

      context "bundles" do
        before :each do
          account_number = Settings.accounts.product_default
          @item2 = @facility.items.create(FactoryBot.attributes_for(:item, account: account_number, facility_account_id: @facility_account.id))
          @bundle = @facility.bundles.create(FactoryBot.attributes_for(:bundle, facility_account_id: @facility_account.id))
          [@item, @item2].each do |item|
            price_policy = item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group: @price_group))
            BundleProduct.create!(quantity: 1, product: item, bundle: @bundle)
          end
        end

        it "should not return error if the product is a bundle and both of the bundled product's accounts are open for a chart string" do
          [@item, @item2].each { |item| define_open_account(item.account, @nufs_account.account_number) }
          expect(@nufs_account.validate_against_product(@bundle, @user)).to be_nil
        end
      end

      it "should return error if the product does not have a price policy for the account or user price groups" do
        define_open_account(@item.account, @nufs_account.account_number)
        expect(@nufs_account.validate_against_product(@item, @user)).to eq(nil)
        @price_group_member.destroy
        @user.reload
        @nufs_account.reload
        expect(@nufs_account.validate_against_product(@item, @user)).not_to eq(nil)
        FactoryBot.create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
        @pg_account_member = FactoryBot.create(:account_price_group_member, account: @nufs_account, price_group: @price_group)
        @nufs_account.reload # load fresh account with updated relationships
        expect(@nufs_account.validate_against_product(@item, @user)).to eq(nil)
      end
    end
  end

  it "should update order details with statement" do
    facility = FactoryBot.create(:facility)
    facility_account = FactoryBot.create(:facility_account, facility: facility)
    user = FactoryBot.create(:user)
    item = FactoryBot.create(:item, facility: facility, facility_account: facility_account)
    account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user))
    order = user.orders.create(FactoryBot.attributes_for(:order, created_by: user.id, facility: facility))
    order_detail = order.order_details.create!(FactoryBot.attributes_for(:order_detail, reviewed_at: (Time.zone.now - 1.day)).update(product_id: item.id, account_id: account.id))
    statement = Statement.create(facility: facility, created_by: 1, account: account)
    account.update_order_details_with_statement(statement)
    expect(order_detail.reload.statement).to eq(statement)
  end

  unless Account.config.facility_account_types.empty?
    context "limited facilities" do
      before :each do
        @user             = FactoryBot.create(:user)
        @facility1        = FactoryBot.create(:facility)
        @facility2        = FactoryBot.create(:facility)
        @nufs_account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
        @facility1_accounts = [@nufs_account]
        @facility2_accounts = [@nufs_account]

        Account.config.facility_account_types.each do |class_name|
          class_sym = class_name.underscore.to_sym
          @facility1_accounts << FactoryBot.create(class_sym, account_users_attributes: account_users_attributes_hash(user: @user), facility: @facility1)
          @facility2_accounts << FactoryBot.create(class_sym, account_users_attributes: account_users_attributes_hash(user: @user), facility: @facility2)
        end
      end

      it "should return the right accounts" do
        expect(Account.for_facility(@facility1)).to contain_all @facility1_accounts
        expect(Account.for_facility(@facility2)).to contain_all @facility2_accounts
      end
    end

    describe "#for_facility" do
      let!(:user) { create :user }
      let!(:facility) { create :facility }
      let!(:po_show) { create_po_for(user, facility) }
      let!(:po_hidden) { create_po_for(user, create(:facility)) }
      let!(:po_deleted) { create_po_for(user, facility, 1.day.ago) }

      it "filters by facility" do
        expect(user.accounts.for_facility(facility)).to match_array([po_show])
      end

      it "filters deleted accounts" do
        expect(user.accounts.for_facility(facility)).to_not include(po_deleted)
      end

      def create_po_for(user, facility, deleted_at = nil)
        account = create(:purchase_order_account,
                         facility: facility,
                         account_users: [build(:account_user, user_role: "Owner", user: create(:user))])

        create(:account_user,
               user: user,
               deleted_at: deleted_at,
               user_role: AccountUser::ACCOUNT_PURCHASER,
               account: account)

        account
      end
    end
  end

  describe ".for_user" do
    let(:owner) { account.owner_user }
    it "finds the account for the owner" do
      expect(Account.for_user(owner)).to include(account)
    end

    describe "and there is a deleted owner" do
      before { FactoryBot.create(:account_user, :inactive, user: owner, account: account) }

      it "only has the one account" do
        expect(Account.for_user(owner)).to eq([account])
      end
    end
  end
end
