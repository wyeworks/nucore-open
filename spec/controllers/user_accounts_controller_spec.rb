# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe UserAccountsController do
  let(:facility) { FactoryBot.create(:facility) }

  context "GET to :show" do
    let(:user) { create(:user) }
    before :each do
      create_users
      @authable = facility
      @method = :get
      @action = :show
      @params = { facility_id: facility.url_name, user_id: user.id }
    end

    it_should_allow_managers_only do
      expect(assigns(:user)).to eq(user)
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
    end
  end

  context "PATCH to :update" do
    let(:director) { create(:user, :facility_director, facility: facility) }
    let(:purchaser) { create(:user) }
    let(:owner) { create(:user) }
    let(:account) { create(:account, :with_account_owner, owner: owner) }

    describe "removing the account owner" do
      before do
        sign_in director
        patch :update,
          params: {
            facility_id: facility.url_name,
            user_id: owner.id,
            user: { account_users_attributes: {"0" => { _destroy: "1", id: account.owner.id } } },
          }
      end

      it "does not destroy" do
        expect(account.owner.reload.deleted_at).to be_blank
      end

      it "does not create any log entries" do
        expect(LogEvent).to be_none
      end
    end

    describe "removing a purchaser" do
      let!(:account_user) { AccountUser.grant(purchaser, AccountUser::ACCOUNT_PURCHASER, account, by: director) }

      before :each do
        sign_in director
        patch :update,
          params: {
            facility_id: facility.url_name,
            user_id: purchaser.id,
            user: { account_users_attributes: {"0" => { _destroy: "1", id: account_user.id } } },
          }
      end

      it "updates the user’s active accounts" do
        expect(purchaser.accounts.active.reload).to be_empty
      end

      it "soft-deletes the account_user" do
        expect(account_user.reload.deleted_at).to be_present
        expect(account_user.deleted_by).to eq(director.id)
      end

      it "redirects back to the user’s accounts page" do
        expect(response).to redirect_to(facility_user_accounts_path(facility, purchaser))
      end

      it "adds a log event" do
        expect(LogEvent.find_by(loggable: account_user, event_type: :delete, user: director)).to be_present
      end
    end
  end
end
