require 'spec_helper'; require 'controller_spec_helper'

describe AccountPriceGroupMembersController do
  render_views

  let(:price_group) { @authable.price_groups.create(FactoryGirl.attributes_for(:price_group)) }

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryGirl.create(:facility)
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
      let(:price_group) { FactoryGirl.create(:price_group, :cancer_center) }

      it_should_allow :admin do
        successful_action_expectations
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
      should render_template('new')
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      assigns(:account_price_group_member).should be_new_record
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

    def successful_action_expectations
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account)).to be_kind_of Account
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      should set_the_flash
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

    def successful_action_expectations
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      expect(assigns(:account_price_group_member)).to be_kind_of AccountPriceGroupMember
      should set_the_flash
      assert_redirected_to(facility_price_group_url(@authable, price_group))
    end
  end

  context "search_results" do
    before :each do
      @method = :get
      @action = :search_results
      @params = { facility_id: @authable.url_name, price_group_id: price_group.id, search_term: '' }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow_all facility_operators do
      # TODO: test GET with valid search term
      expect(assigns(:limit)).to be_kind_of Fixnum
      expect(assigns(:price_group)).to be_kind_of PriceGroup
      should render_template('search_results')
    end
  end
end
