# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe AccountPriceGroupMembersController do
  render_views

  let(:facility) { @authable }
  let(:price_group) { FactoryBot.create(:price_group, facility: facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
  end

  shared_examples "facility price group restrictions" do
    context "with a facility specific price group" do
      it_should_allow_all [:admin, :facility_admin, :director] do
        successful_action_expectations
      end

      it_should_deny_all [:staff, :senior_staff]

      context "with account specific roles" do
        before { @authable = @account }

        it_should_deny_all [:owner, :purchaser, :business_admin]
      end
    end
  end

  shared_examples "global price group restrictions" do
    context "with a global price group" do
      let(:price_group) { FactoryBot.create(:price_group, :cancer_center) }

      context "when can manage global price groups", feature_setting: { can_manage_global_price_groups: true } do
        it_should_allow :admin do
          successful_action_expectations
        end
      end

      it_should_deny_all [:facility_admin, :director, :staff, :senior_staff]

      context "with account specific roles" do
        before { @authable = @account }

        it_should_deny_all [:owner, :purchaser, :business_admin]
      end
    end
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
      @account = create_nufs_account_with_owner
      @params = { facility_id: @authable.url_name, price_group_id: price_group.id }
    end

    it_should_require_login

    it_should_deny :guest

    include_examples "facility price group restrictions"
    include_examples "global price group restrictions"

    def successful_action_expectations
      is_expected.to render_template("new")
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      expect(assigns(:account_price_group_member)).to be_new_record
    end
  end

  context "create" do
    before :each do
      @method = :post
      @action = :create
      @account = create_nufs_account_with_owner
      @params = { facility_id: @authable.url_name, price_group_id: price_group.id, account_id: @account.id }
    end

    it_should_require_login

    it_should_deny :guest

    include_examples "facility price group restrictions"
    include_examples "global price group restrictions"

    context "when cannot manage global price groups", feature_setting: { can_manage_global_price_groups: false } do
      let(:price_group) { FactoryBot.create(:price_group, :cancer_center) }

      it_should_deny :admin
    end

    def successful_action_expectations
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account)).to be_kind_of Account
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      is_expected.to set_flash
      assert_redirected_to([@authable, price_group])
    end
  end

  context "destroy" do
    before(:each) do
      @method = :delete
      @action = :destroy
      @account = create_nufs_account_with_owner
      @account_price_group_member = AccountPriceGroupMember.create!(price_group: price_group, account: @account)
      @params = { facility_id: @authable.url_name, price_group_id: price_group.id, id: @account_price_group_member.id }
    end

    it_should_require_login

    it_should_deny :guest

    include_examples "facility price group restrictions"
    include_examples "global price group restrictions"

    context "when cannot manage global price groups", feature_setting: { can_manage_global_price_groups: false } do
      let(:price_group) { FactoryBot.create(:price_group, :cancer_center) }

      it_should_deny :admin
    end

    def successful_action_expectations
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      is_expected.to set_flash
      assert_redirected_to(facility_price_group_url(@authable, price_group))
    end
  end

  context "search_results" do
    # Ignore validation errors, e.g. number format
    before { allow(AccountValidator::ValidatorFactory).to receive(:instance).and_return(AccountValidator::ValidatorDefault.new) }

    let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner) }
    let!(:account_number) { account.account_number }

    before :each do
      @method = :get
      @action = :search_results
      @params = { facility_id: facility.url_name, price_group_id: price_group.id, search_term: account_number }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow :admin do
      expect(assigns(:accounts)).to include(account)
      expect(assigns(:limit)).to be_kind_of Integer
      expect(assigns(:price_group)).to eq(price_group)
      is_expected.to render_template("search_results")
    end
  end
end
