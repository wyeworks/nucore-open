# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe AccountUsersController do
  render_views

  before(:all) { create_users }
  let(:account) { @authable }

  before :each do
    @authable = create_nufs_account_with_owner
  end

  context "user_search" do

    before :each do
      @method = :get
      @action = :user_search
      @params = { account_id: @authable.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      is_expected.to render_template("user_search")
    end

  end

  context "new" do

    before :each do
      @method = :get
      @action = :new
      @params = { account_id: @authable.id, user_id: @purchaser }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:user)).to eq(@purchaser)
      expect(assigns(:account_user)).to be_kind_of AccountUser
      expect(assigns(:account_user)).to be_new_record
      is_expected.to render_template("new")
    end

  end

  context "create" do

    before :each do
      @method = :post
      @action = :create
      @params = {
        account_id: @authable.id,
        user_id: @purchaser.id,
        account_user: { user_role: AccountUser::ACCOUNT_PURCHASER },
      }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      expect(assigns(:user)).to eq(@purchaser)
      expect(assigns(:account_user)).to be_kind_of AccountUser
      expect(assigns(:account_user).user).to eq(@purchaser)
      expect(assigns(:account_user).created_by).to eq(@owner.id)
      expect(assigns(:account_user).log_events.size).to eq(1)
      expect(assigns(:account_user).log_events.first).to have_attributes(
        loggable: assigns(:account_user), event_type: "create",
        user_id: a_truthy_value)
      expect(@purchaser.reload).to be_purchaser_of(@authable)
      is_expected.to set_flash
      assert_redirected_to(account_account_users_path(@authable))
    end

  end

  context "destroy" do
    def do_request
      delete :destroy, params: { account_id: account.id, id: account_user.id }
    end

    let(:owner) { account.owner_user }
    let(:purchaser) { create(:user) }
    let(:account_user) do
      FactoryBot.create(
        :account_user, user_role: AccountUser::ACCOUNT_PURCHASER,
                       account: account, user: purchaser,
                       created_by: owner.id)
    end

    it "does not allow the purchaser" do
      sign_in purchaser
      do_request
      expect(response.status).to eq(403)
      expect(account_user.reload).to be_present
    end

    describe "as the owner" do
      before { sign_in owner }

      it "sets the deleted fields" do
        expect { do_request }.to change { account_user.reload.deleted_at }.to be_present
        expect(account_user.deleted_by).to eq(@owner.id)
      end

      it "adds the log event" do
        expect { do_request }.to change(account_user.log_events, :count).by(1)
        expect(account_user.log_events.last).to have_attributes(
        loggable: assigns(:account_user), event_type: "delete",
        user_id: owner.id)
      end

      it "sets the flash and redirects" do
        do_request
        is_expected.to set_flash
        assert_redirected_to(account_account_users_path(@authable))
      end
    end
  end

end
