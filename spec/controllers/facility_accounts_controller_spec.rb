# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityAccountsController, feature_setting: { edit_accounts: true, suspend_accounts: true, reload_routes: true } do

  let(:facility) { FactoryBot.create(:facility) }
  let(:account) { create_nufs_account_with_owner }
  let(:admin) { @admin }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @facility_account = FactoryBot.create(:facility_account, facility: @authable)
    @item = FactoryBot.create(:item, facility_account: @facility_account, facility: @authable)
    @account = account
    grant_role(@purchaser, @account)
    grant_role(@owner, @account)
    @order = FactoryBot.create(:order, user: @purchaser, created_by: @purchaser.id, facility: @authable)
    @order_detail = FactoryBot.create(:order_detail, product: @item, order: @order, account: @account)
  end

  context "index" do

    before(:each) do
      @method = :get
      @action = :index
      @params = { facility_id: @authable.url_name }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
      expect(assigns(:accounts).size).to eq(1)
      expect(assigns(:accounts).first).to eq(@account)
      is_expected.to render_template("index")
    end

  end

  context "show" do

    before(:each) do
      @method = :get
      @action = :show
      @params = { facility_id: @authable.url_name, id: @account.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      expect(assigns(:account)).to eq(@account)
      is_expected.to render_template("show")
    end

    context "the account was created in another facility" do
      let(:other_facility) { create(:facility, name: "other_facility") }
      let(:other_account) { create(:account, :with_account_owner, description: "Other Account", facility: other_facility) }

      before do
        other_account.facilities = [facility, other_facility]
        allow(other_account).to receive(:global?).and_return(false)
        @params[:id] = other_account.id
      end

      it_should_allow_all facility_managers do
        expect(response).to be_successful
        expect(assigns(:account)).to eq(other_account)
        is_expected.to render_template("show")
      end
    end
  end

  context "edit accounts" do
    context "new" do

      before(:each) do
        @method = :get
        @action = :new
        @params = { facility_id: @authable.url_name, owner_user_id: @owner.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        expect(assigns(:owner_user)).to eq(@owner)
        expect(assigns(:account)).to be_new_record
        is_expected.to render_template("new")
      end

    end

    context "edit" do

      before(:each) do
        @method = :get
        @action = :edit
        @params = { facility_id: @authable.url_name, id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        expect(assigns(:account)).to eq(@account)
        is_expected.to render_template("edit")
      end

    end

    context "update" do

      before(:each) do
        @method = :put
        @action = :update
        @params = {
          facility_id: @authable.url_name,
          id: @account.id,
          nufs_account: FactoryBot.attributes_for(:nufs_account).except(:account_number, :created_by, :expires_at),
        }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        expect(assigns(:account).affiliate).to be_nil
        expect(assigns(:account).affiliate_other).to be_nil
        expect(assigns(:account).log_events.size).to eq(1)
        expect(assigns(:account).log_events.first).to have_attributes(
          loggable: assigns(:account), event_type: "update",
          user_id: a_truthy_value)
        is_expected.to set_flash
        assert_redirected_to facility_account_url
      end

    end

    context "create", if: Account.config.creation_enabled?(NufsAccount) do
      let(:owner_user) { assigns(:account).owner_user }

      before :each do
        @method = :post
        @action = :create
        @acct_attrs = FactoryBot.attributes_for(:nufs_account).except(:created_by, :expires_at)
        @params = {
          facility_id: @authable.url_name,
          owner_user_id: @owner.id,
          nufs_account: @acct_attrs,
          account_type: "NufsAccount",
        }
        allow(@controller).to receive(:current_facility).and_return(@authable)
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do |user|
        expect(assigns(:account)).to be_kind_of NufsAccount
        expect(assigns(:account).account_number).to eq(@acct_attrs[:account_number])
        expect(assigns(:account).created_by).to eq(user.id)
        expect(assigns(:account).account_users.size).to eq(1)
        assigns(:account).account_users[0] == @owner
        expect(assigns(:account).affiliate).to be_nil
        expect(assigns(:account).affiliate_other).to be_nil
        expect(assigns(:account).log_events.size).to eq(1)
        expect(assigns(:account).log_events.first).to have_attributes(
          loggable: assigns(:account), event_type: "create",
          user_id: a_truthy_value)
        is_expected.to set_flash
        expect(response).to redirect_to(facility_user_accounts_path(facility, owner_user))
      end

    end

    context "new_account_user_search" do

      before :each do
        @method = :get
        @action = :new_account_user_search
        @params = { facility_id: @authable.url_name }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        is_expected.to render_template "new_account_user_search"
      end

    end

  end

  context "accounts_receivable" do

    before :each do
      @method = :get
      @action = :accounts_receivable
      @params = { facility_id: @authable.url_name }
    end

    it_should_allow_managers_only
    it_should_deny_all [:staff, :senior_staff]
  end

  context "search_results" do
    it "requires login" do
      get :search_results, params: { facility_id: facility.url_name }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "denies senior staff" do
      sign_in create(:user, :senior_staff, facility: facility)
      get :search_results, params: { facility_id: facility.url_name }
      expect(response).to be_forbidden
    end

    describe "as the director" do
      let(:owner) { create(:user, first_name: "Owner", last_name: "User") }
      let!(:account) { create(:nufs_account, :with_account_owner, owner: owner) }

      before do
        sign_in create(:user, :facility_director, facility: facility)
      end

      it "finds an account by a partial account number" do
        get :search_results, params: { facility_id: facility.url_name, search_term: account.account_number.first(3) }
        expect(assigns(:accounts)).to include(account)
      end

      it "finds the account by the owner first name" do
        get :search_results, params: { facility_id: facility.url_name, search_term: owner.first_name }
        expect(assigns(:accounts)).to include(account)
      end

      it "finds the account by the owner last name" do
        get :search_results, params: { facility_id: facility.url_name, search_term: owner.last_name }
        expect(assigns(:accounts)).to include(account)
      end

      it "doesn't find anything with gibberish" do
        get :search_results, params: { facility_id: facility.url_name, search_term: "GOBBLEDEGOOK" }
        expect(assigns(:accounts)).to be_empty
      end

      it "returns a warning an no results if less than three characters" do
        get :search_results, params: { facility_id: facility.url_name, search_term: "A" }
        expect(assigns(:accounts)).to be_nil
        expect(flash.now[:errors]).to be_present
      end
    end
  end

  context "members" do

    before :each do
      @method = :get
      @action = :members
      @params = { facility_id: @authable.url_name, account_id: @account.id }
    end

    it_should_require_login

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_all facility_managers do
      expect(assigns(:account)).to eq(@account)
      is_expected.to render_template("members")
    end

  end

  context "with statements", :time_travel, if: Account.config.statements_enabled? do
    let!(:statements) { FactoryBot.create_list(:statement, 2, facility_id: facility.id, created_by: admin.id, account: account) }

    describe "show_statement" do
      before :each do
        @method = :get
        @action = :show_statement
        @params = { facility_id: facility.url_name, account_id: account.id, statement_id: statements.first.id, format: "pdf" }
      end

      it_should_deny_all [:staff, :senior_staff]

      it "shows the statement PDF for a director" do
        maybe_grant_always_sign_in :director
        do_request
        expect(assigns(:account)).to eq(@account)
        expect(controller.current_facility).to eq(facility)
        expect(assigns(:statement)).to eq(statements.first)
        expect(response.content_type).to eq("application/pdf")
        expect(response.body).to match(/\A%PDF-1.\d+\b/)
        is_expected.to render_template "statements/show"
      end

      it "does not allow an account admin" do
        user = create(:user, :business_administrator, account: account)
        sign_in user
        do_request
        expect(response.code).to eq("403")
      end

      it "allows global billing administrator to access the statement" do
        user = create(:user, :global_billing_administrator)
        sign_in user
        do_request
        expect(response).to be_successful
      end
    end

    describe "statements" do
      let!(:other_facility_statement) { FactoryBot.create(:statement, created_by: admin.id, account: account) }

      describe "a single facility" do
        let(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }

        before do
          sign_in director
          get :statements, params: { facility_id: facility.url_name, account_id: account.id }
        end

        it "shows the statements list" do
          expect(assigns(:statements)).to match_array(statements)
          is_expected.to render_template("statements")
        end
      end

      describe "cross facility" do
        let(:account_manager) { FactoryBot.create(:user, :account_manager) }
        before do
          sign_in account_manager
          get :statements, params: { facility_id: "all", account_id: account.id }
        end

        it "shows the statements list" do
          expect(assigns(:account)).to eq(account)
          expect(assigns(:statements)).to match_array(statements + [other_facility_statement])
          is_expected.to render_template("statements")
        end
      end
    end
  end

  context "suspension" do
    context "suspend" do

      before :each do
        @method = :get
        @action = :suspend
        @params = { facility_id: @authable.url_name, account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).to be_suspended
        assert_redirected_to facility_account_path(@authable, @account)
      end

    end

    context "unsuspend" do

      before :each do
        @method = :get
        @action = :unsuspend
        @params = { facility_id: @authable.url_name, account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_all facility_managers do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).not_to be_suspended
        assert_redirected_to facility_account_path(@authable, @account)
      end

    end
  end

end
