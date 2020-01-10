# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityAccountUsersController, if: SettingsHelper.feature_on?(:edit_accounts) do
  render_views

  before(:all) { create_users }

  let(:account) { create_nufs_account_with_owner }
  let(:facility) { FactoryBot.create(:facility) }

  before(:each) do
    @authable = facility
    @account = account
  end

  context "user_search" do

    before(:each) do
      @method = :get
      @action = :user_search
      @params = { facility_id: @authable.url_name, account_id: @account.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      expect(assigns(:account)).to eq(@account)
      is_expected.to render_template("user_search")
    end

  end

  context "new" do

    before(:each) do
      @method = :get
      @action = :new
      @params = { facility_id: @authable.url_name, account_id: @account.id, user_id: @guest.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      expect(assigns(:account)).to eq(@account)
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:account_user)).to be_kind_of AccountUser
      expect(assigns(:account_user)).to be_new_record
      is_expected.to render_template("new")
    end

  end

  context "create" do

    before(:each) do
      @method = :post
      @action = :create
      @params = {
        facility_id: @authable.url_name,
        account_id: @account.id,
        user_id: @purchaser.id,
        account_user: { user_role: AccountUser::ACCOUNT_PURCHASER },
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      expect(assigns(:account)).to eq(@account)
      expect(assigns(:user)).to eq(@purchaser)
      expect(assigns(:account_user).user_role).to eq(AccountUser::ACCOUNT_PURCHASER)
      expect(assigns(:account_user).user).to eq(@purchaser)
      expect(assigns(:account_user).created_by).to eq(user.id)
      is_expected.to set_flash
      assert_redirected_to facility_account_members_path(@authable, @account)
    end

    context "changing roles" do
      before :each do
        maybe_grant_always_sign_in :director
      end

      context "with an existing owner" do

        before :each do
          @params[:account_user][:user_role] = AccountUser::ACCOUNT_OWNER
          expect(@account.account_users.owners).to be_one
          expect(@account.owner_user).to eq(@owner)
          do_request
        end

        it "changes the owner of an account" do
          expect(assigns(:account)).to eq(@account)
          expect(assigns(:user)).to eq(@purchaser)
          expect(assigns(:account_user).user_role).to eq(AccountUser::ACCOUNT_OWNER)
          expect(assigns(:account_user).user).to eq(@purchaser)
          expect(assigns(:account_user).created_by).to eq(@director.id)
          expect(@account.reload.account_users.owners.count).to eq(1)
          expect(@account.deleted_account_users.count).to eq(1)
          expect(assigns(:account).reload.owner_user).to eq(@purchaser)
          is_expected.to set_flash
          assert_redirected_to facility_account_members_path(@authable, @account)
        end
      end

      context "with a missing owner" do

        before :each do
          @account_user = @account.owner
          @account_user.destroy!

          @params[:account_user][:user_role] = AccountUser::ACCOUNT_OWNER
          expect(@account.account_users.owners).to be_empty
          do_request
        end

        it "adds the owner" do
          expect(assigns(:account)).to eq(@account)
          expect(@account.reload.owner_user).to eq(@purchaser)
          is_expected.to set_flash
          assert_redirected_to facility_account_members_path(@authable, @account)
        end
      end

      context "changing a user's role" do
        context "from business admin to purchaser" do
          before :each do
            @business_admin = FactoryBot.create(:user)
            FactoryBot.create(:account_user, account: @account, user: @business_admin, user_role: AccountUser::ACCOUNT_ADMINISTRATOR)
            @params.merge!(
              account_id: @account.id,
              user_id: @business_admin.id,
              account_user: { user_role: AccountUser::ACCOUNT_PURCHASER },
            )
            expect(@account.account_users.purchasers).not_to be_any
            expect(@account.account_users.business_administrators).to be_one
            do_request
          end

          it "should change the role" do
            expect(assigns(:account)).to eq(@account)
            expect(@account.account_users.purchasers.map(&:user)).to eq([@business_admin])
            expect(@account.account_users.business_administrators).not_to be_any

            is_expected.to set_flash
            assert_redirected_to facility_account_members_path(@authable, @account)
          end
        end

        context "from owner to purchaser" do
          before :each do
            @params[:user_id]                  = @owner.id
            @params[:account_user][:user_role] = AccountUser::ACCOUNT_PURCHASER
            expect(@account.account_users.owners.map(&:user)).to eq([@owner])
            expect(@account.account_users.purchasers).not_to be_any
          end

          it "has the correct error" do
            do_request
            expect(assigns(:account_user).errors).to be_added(:base, "Must have an account owner")
          end

          it "should be prevented" do
            do_request
            expect(assigns(:account)).to eq(@account)
            expect(assigns(:account).owner_user).to eq(@owner)
            expect(@account.account_users.owners.map(&:user)).to eq([@owner])
            expect(@account.account_users.purchasers).not_to be_any

            expect(flash[:error]).to be_present
            expect(response).to render_template :new
          end

          it "should not send an email" do
            expect(Notifier).not_to receive(:user_update)
            do_request
          end
        end
      end
    end

    describe "adding to an account that does not pass validation" do
      before do
        allow_any_instance_of(ValidatorFactory.validator_class)
          .to receive(:account_is_open!).and_raise(ValidatorError)
      end

      it_should_allow(:director) do
        expect(assigns(:account_user)).to be_persisted
      end
    end
  end

  context "destroy" do
    def do_request
      delete :destroy, params: { facility_id: facility.url_name, account_id: account.id, id: account_user.id }
    end

    let(:staff) { FactoryBot.create(:user, :staff, facility: facility) }
    let(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }
    let(:purchaser) { create(:user) }

    let(:account_user) do
      FactoryBot.create(
        :account_user, user_role: AccountUser::ACCOUNT_PURCHASER,
                       account: account, user: purchaser,
                       created_by: account.owner_user.id)
    end

    it "does not allow the staff" do
      sign_in staff
      do_request
      expect(response).to be_forbidden
      expect(account_user.reload).to be_present
    end

    describe "as the facility director" do
      before { sign_in director }

      it "sets the deleted fields" do
        expect { do_request }.to change { account_user.reload.deleted_at }.to be_present
        expect(account_user.deleted_by).to eq(director.id)
      end

      it "adds the log event" do
        expect { do_request }.to change(account_user.log_events, :count).by(1)
        expect(account_user.log_events.last).to have_attributes(
        loggable: assigns(:account_user), event_type: "delete",
        user_id: director.id)
      end

      it "sets the flash and redirects" do
        do_request
        is_expected.to set_flash
        assert_redirected_to(facility_account_members_path(facility, account))
      end

      describe "even if an account does not pass validation" do
        before do
          allow_any_instance_of(ValidatorFactory.validator_class)
            .to receive(:account_is_open!).and_raise(ValidatorError)
        end

        it "still deletes it" do
          expect { do_request }.to change { account_user.reload.deleted_at }.to be_present
        end
      end
    end

  end

end
