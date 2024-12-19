# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe PriceGroupsController do
  render_views

  let(:facility) { create(:facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # Required to be set for controller_spec_helper
    @params = { facility_id: facility.url_name }
  end

  describe "GET #index" do
    let!(:price_groups) { create_list(:price_group, 3, facility: facility) }

    before(:each) do
      @method = :get
      @action = :index
    end

    it_should_allow_managers_only do
      expect(assigns(:price_groups))
        .to eq(facility.price_groups)
        .and all be_kind_of(PriceGroup)
    end
  end

  context "with a price group id parameter" do
    let(:price_group) { create(:price_group, facility: facility) }

    before { @params.merge!(id: price_group.id) }

    describe "GET #show" do
      before(:each) do
        @method = :get
        @action = :show
      end

      it_should_allow_managers_only :redirect do
        expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
        is_expected.to redirect_to(accounts_facility_price_group_path(facility, price_group))
      end
    end

    describe "GET #users" do
      before(:each) do
        @method = :get
        @action = :users
      end

      context "when user-based price groups are enabled", feature_setting: { user_based_price_groups: true, facility_directors_can_manage_price_groups: true } do
        let(:user) { FactoryBot.create(:user) }
        let!(:user_member) { FactoryBot.create(:user_price_group_member, price_group: price_group, user: user) }

        it_should_allow_managers_only do
          expect(assigns(:user_members)).to include(user_member)
          expect(assigns(:tab)).to eq(:users)
          is_expected.to render_template("show")
        end
      end

      context "when user-based price groups are disabled", feature_setting: { user_based_price_groups: false, facility_directors_can_manage_price_groups: true } do
        before(:each) do
          maybe_grant_always_sign_in(user)
        end

        context "for admins" do
          let(:user) { :admin }
          it { expect { do_request }.to raise_error(ActiveRecord::RecordNotFound) }
        end

        context "for directors" do
          let(:user) { :director }
          it { expect { do_request }.to raise_error(ActiveRecord::RecordNotFound) }
        end

        context "for senior staff" do
          let(:user) { :senior_staff }
          it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
        end

        context "for staff" do
          let(:user) { :staff }
          it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
        end

        context "for guests" do
          let(:user) { :staff }
          it { expect { do_request }.to raise_error(CanCan::AccessDenied) }
        end
      end
    end

    describe "GET #accounts" do
      let(:account) { FactoryBot.create(:account, :with_account_owner) }
      let!(:account_member) { FactoryBot.create(:account_price_group_member, price_group: price_group, account: account) }

      before(:each) do
        @method = :get
        @action = :accounts
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do
        it_should_allow_managers_only do
          expect(assigns(:account_members)).to include(account_member)
          expect(assigns(:tab)).to eq(:accounts)
          is_expected.to render_template("show")
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only do
          expect(assigns(:account_members)).to include(account_member)
          expect(assigns(:tab)).to eq(:accounts)
          is_expected.to render_template("show")
        end
      end
    end

    describe "GET #edit" do
      before(:each) do
        @method = :get
        @action = :edit
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do
        it_should_allow_managers_only do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          is_expected.to render_template("edit")
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          is_expected.to render_template("edit")
        end
      end
    end

    describe "PUT #update" do
      before(:each) do
        @method = :put
        @action = :update
        @params.merge!(price_group: attributes_for(:price_group, facility_id: facility.id))
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do
        it_should_allow_managers_only :redirect do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          expect(flash[:notice]).to include("successfully updated")
          is_expected.to redirect_to([facility, price_group])
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only :redirect do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          expect(flash[:notice]).to include("successfully updated")
          is_expected.to redirect_to([facility, price_group])
        end
      end
    end

    describe "DELETE #destroy" do
      before(:each) do
        @method = :delete
        @action = :destroy
      end

      context "when facility_directors_can_manage_price_groups on", feature_setting: { facility_directors_can_manage_price_groups: true } do
        it_should_allow_managers_only :redirect do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          should_be_destroyed price_group
          is_expected.to redirect_to(facility_price_groups_url)
        end
      end

      context "when facility_directors_can_manage_price_groups off", feature_setting: { facility_directors_can_manage_price_groups: false } do
        it_should_allow_admin_only :redirect do
          expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
          should_be_destroyed price_group
          is_expected.to redirect_to(facility_price_groups_url)
        end
      end
    end
  end
end
