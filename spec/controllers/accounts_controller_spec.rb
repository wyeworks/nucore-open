# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe AccountsController do
  render_views

  it "should route" do
    expect(get: "/accounts").to route_to(controller: "accounts", action: "index")
    expect(get: "/accounts/1").to route_to(controller: "accounts", action: "show", id: "1")
    expect(get: "/accounts/1/user_search").to route_to(controller: "accounts", action: "user_search", id: "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable = create_nufs_account_with_owner
  end

  context "index" do

    before(:each) do
      @method = :get
      @action = :index
    end

    it_should_require_login

    it "should list accounts, with edit account links for account owner" do
      create_nufs_account_with_owner
      maybe_grant_always_sign_in(:owner)
      do_request
      # should find 2 account users, with user roles 'Owner'
      expect(assigns[:account_users].collect(&:user_id)).to eq([@owner.id, @owner.id])
      expect(assigns[:account_users].collect(&:user_role)).to eq(%w(Owner Owner))
      # should show 2 accounts, with 'edit account' links
      expect(response).to render_template("accounts/index")
    end

    it_should_allow :purchaser do
      # should find 1 account user, with user roles as 'Purchaser'
      expect(assigns[:account_users].collect(&:user_id)).to eq([@purchaser.id])
      expect(assigns[:account_users].collect(&:user_role)).to eq(["Purchaser"])
      # should show 1 account, with no 'edit account' links
      expect(response).to render_template("accounts/index")
    end
  end

  context "show" do

    before :each do
      @method = :get
      @action = :show
      @params = { id: @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:account)).to eq(@authable)
      expect(response).to render_template("accounts/show")
    end
  end

  context "user_search" do

    before :each do
      @method = :get
      @action = :user_search
      @params = { id: @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:account)).to eq(@authable)
      expect(response).to render_template("account_users/user_search")
    end

  end

  context "suspension", if: SettingsHelper.feature_on?(:suspend_accounts) do
    before :each do
      @account = @authable
    end

    context "suspend" do
      before :each do
        @method = :get
        @action = :suspend
        @params = { account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:purchaser]

      it_should_allow_all [:owner, :business_admin] do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(@account.reload).to be_suspended
        assert_redirected_to account_path(@account)
      end

      it "logs the account when it gets suspended" do
        admin = create(:user, :administrator)
        sign_in admin
        do_request
        log_event = LogEvent.find_by(loggable: @account, event_type: :suspended, user: admin)
        expect(log_event).to be_present
      end
    end

    context "unsuspend" do
      before :each do
        @method = :get
        @action = :unsuspend
        @params = { account_id: @account.id }
      end

      it_should_require_login

      it_should_deny_all [:purchaser]

      it_should_allow_all [:owner, :business_admin] do
        expect(assigns(:account)).to eq(@account)
        is_expected.to set_flash
        expect(assigns(:account)).not_to be_suspended
        assert_redirected_to account_path(@account)
      end

      it "logs the account when it gets unsuspended" do
        admin = create(:user, :administrator)
        sign_in admin
        do_request
        log_event = LogEvent.find_by(loggable: @account, event_type: :unsuspended, user: admin)
        expect(log_event).to be_present
      end
    end
  end

end
