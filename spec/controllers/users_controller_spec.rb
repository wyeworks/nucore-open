# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe UsersController do
  render_views

  let(:facility) { FactoryBot.create(:facility) }

  before(:each) do
    create_users
    @authable = facility
    @params = { facility_id: @authable.url_name }
  end

  context "index" do

    before :each do
      @method = :get
      @action = :index
      @inactive_user = FactoryBot.create(:user, first_name: "Inactive")

      @active_user = FactoryBot.create(:user, first_name: "Active")
      place_and_complete_item_order(@active_user, @authable)
      # place two orders to make sure it only and_return the user once
      place_and_complete_item_order(@active_user, @authable)

      @lapsed_user = FactoryBot.create(:user, first_name: "Lapsed")
      @old_order_detail = place_and_complete_item_order(@lapsed_user, @authable)
      @old_order_detail.update_attributes!(ordered_at: 400.days.ago)
    end

    it_should_allow_operators_only :success, "include the right users" do
      expect(assigns[:users].size).to eq(1)
      expect(assigns[:users]).to include @active_user
    end

    context "with newly created user" do
      before :each do
        @user = FactoryBot.create(:user)
        @params.merge!(user: @user.id)
      end
      it_should_allow_operators_only :success, "set the user" do
        expect(assigns[:new_user]).to eq(@user)
      end
    end

  end

  describe "GET #edit", feature_setting: { create_users: true, reload_routes: true } do
    let(:user) { FactoryBot.create(:user, :external) }

    before(:each) do
      @method = :get
      @action = :edit
      @params[:id] = user.id
    end

    it_should_allow_admin_only { expect(assigns[:user]).to eq(user) }
  end

  describe "PUT #update", feature_setting: { create_users: true, reload_routes: true } do
    let(:user) { FactoryBot.create(:user, :external, first_name: "Old", uid: 22) }

    before(:each) do
      @method = :put
      @action = :update
      @params[:id] = user.id
      @params[:user] = { first_name: "New", last_name: "Name", email: "newemail@example.com", username: "user234" }
    end

    it_should_allow_admin_only(:found) do
      expect(user.reload.first_name).to eq("New")
      expect(user.last_name).to eq("Name")
      expect(user.email).to eq("newemail@example.com")
      expect(user.username).to eq("user234")
      expect(response).to redirect_to facility_user_path(facility, user)
    end

    context "the price group changes", feature_setting: { user_based_price_groups: true } do
      before(:each) do
        @params[:user][:internal] = true
      end
      it_should_allow(:admin, "to update the user information and it should log the user") do
        log_event = LogEvent.find_by(loggable: user, event_type: :default_price_group_changed)
        expect(log_event).to be_present
        expect(log_event.metadata).to eq("price_group_rate" => PriceGroup.base.name)
      end
    end

    context "the price group does not change", feature_setting: { user_based_price_groups: true } do
      before(:each) do
        @params[:user][:internal] = false
      end
      it_should_allow(:admin, "to update the user information and it shouldn't log the user") do
        log_event = LogEvent.find_by(loggable: user, event_type: :default_price_group_changed)
        expect(log_event).not_to be_present
      end
    end
  end

  describe "GET #access_list" do
    let(:facility) { FactoryBot.create(:setup_facility) }
    let(:user) { FactoryBot.create(:user) }
    let!(:instruments) { FactoryBot.create_list(:instrument_requiring_approval, 2, facility: facility) }
    let!(:services) { FactoryBot.create_list(:setup_service, 2, requires_approval: true, facility: facility) }
    let!(:training_requests) do
      [
        FactoryBot.create(:training_request, user: user, product: instruments.last),
        FactoryBot.create(:training_request, user: user, product: services.first),
      ]
    end

    before(:each) do
      @method = :get
      @action = :access_list
      @params[:user_id] = user.id
    end

    it_should_allow_operators_only do
      expect(assigns[:facility]).to eq(facility)
      expect(assigns[:products_by_type]["Instrument"]).to match_array(instruments)
      expect(assigns[:products_by_type]["Service"]).to match_array(services)
      expect(assigns[:training_requested_product_ids]).to match_array [
        instruments.last.id,
        services.first.id,
      ]
    end
  end

  context "creating users" do
    context "enabled", feature_setting: { create_users: true, reload_routes: true } do

      it "routes", :aggregate_failures do
        expect(get: "/#{facilities_route}/url_name/users/new").to route_to(controller: "users", action: "new", facility_id: "url_name")
        expect(post: "/#{facilities_route}/url_name/users").to route_to(controller: "users", action: "create", facility_id: "url_name")
        expect(get: "/#{facilities_route}/url_name/users/new_external").to route_to(controller: "users", action: "new_external", facility_id: "url_name")
        expect(post: "/#{facilities_route}/url_name/users/search").to route_to(controller: "users", action: "search", facility_id: "url_name")
      end

      context "search" do
        let!(:user) { FactoryBot.create(:user) }

        before :each do
          @method = :post
          @action = :search
        end

        context "blank post" do
          before :each do
            @params.merge!(username_lookup: "")
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to be_nil
            expect(response).to be_successful
          end
        end

        context "user already exists in database" do
          before :each do
            @params.merge!(username_lookup: user.username)
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to eq(user)
            expect(assigns(:user)).to be_persisted
          end
        end

        describe "user exists but admin included extra spaces" do
          before do
            @params.merge!(username_lookup: " #{user.username}")
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to eq(user)
          end
        end

        context "user does not exist in database" do
          before :each do
            @user2 = FactoryBot.build(:user)
            allow(controller).to receive(:service_username_lookup).with(@user2.username).and_return(@user2)
            @params.merge!(username_lookup: @user2.username)
          end

          it_should_allow_operators_only do
            expect(assigns(:user)).to eq(@user2)
            expect(assigns(:user)).to be_new_record
          end
        end
      end

      context "new_external" do
        before :each do
          @method = :get
          @action = :new_external
        end

        it_should_allow_operators_only do
          expect(assigns(:user_form)).to be_kind_of UserForm
        end
      end

      context "create" do
        before :each do
          @method = :post
          @action = :create
        end

        context "external user" do
          context "with successful parameters" do
            before :each do
              user_params = FactoryBot.attributes_for(:user, username: "user123").except(:password, :password_confirmation)
              @params.merge!(user: user_params)
            end

            it_should_allow_operators_only :redirect do
              assert_redirected_to facility_users_url(user: assigns[:user_form].user.id)
            end
          end

          context "with missing parameters" do
            before :each do
              @params.merge!(user: { email: "email@example.com" })
            end

            it_should_allow_operators_only do
              expect(response).to render_template "new_external"
            end
          end
        end

        context "internal user" do
          before :each do
            sign_in @admin
          end

          context "user already exists" do
            let!(:user) { FactoryBot.create(:user) }
            before :each do
              @params[:username] = user.username
              do_request
            end

            it "flashes an error" do
              is_expected.to set_flash
              expect(response).to redirect_to facility_users_path
            end
          end

          describe "user not found" do
            before do
              @params[:username] = "doesnotexist"
              do_request
            end

            it "flashes an error" do
              is_expected.to set_flash
              expect(response).to redirect_to facility_users_path
            end
          end

          describe "user is invalid" do
            let(:user) { build(:user, first_name: "") }
            before do
              allow(controller).to receive(:username_lookup).and_return user
              @params[:username] = user.username
              do_request
            end

            it "flashes an error" do
              is_expected.to set_flash
              expect(response).to redirect_to facility_users_path
            end
          end

          context "user added" do
            before :each do
              @ldap_user = FactoryBot.build(:user)
              allow(controller).to receive(:service_username_lookup).with(@ldap_user.username).and_return(@ldap_user)
              @params[:username] = @ldap_user.username
              do_request
            end

            it "should save the user" do
              expect(assigns(:user)).to be_persisted
            end

            it "should set the flash" do
              expect(flash[:notice]).not_to be_empty
            end

            it "should redirect" do
              expect(response).to redirect_to facility_users_path(user: assigns(:user).id)
            end
          end
        end
      end
    end

    context "disabled", feature_setting: { create_users: false, reload_routes: true } do
      it "doesn't route route", :aggregate_failures do
        expect(get: "/#{facilities_route}/url_name/users/new").not_to be_routable
        expect(get: "/#{facilities_route}/url_name/users/edit").not_to be_routable
        expect(put: "/#{facilities_route}/url_name/users/update").not_to be_routable
        expect(post: "/#{facilities_route}/url_name/users").not_to be_routable
        expect(get: "/#{facilities_route}/url_name/users/new_external").not_to be_routable
        expect(post: "/#{facilities_route}/url_name/users/search").not_to be_routable
      end
    end
  end

  context "switch_to" do
    let(:user) { FactoryBot.create(:user) }
    before :each do
      @method = :get
      @action = :switch_to
      @params.merge!(user_id: user.id)
    end

    it_should_allow_operators_only :redirect do
      expect(assigns(:user)).to eq(user)
      expect(session[:acting_user_id]).to eq(user.id)
      expect(session[:acting_ref_url]).to eq(facility_users_path)
      assert_redirected_to facility_path(@authable)
    end

    describe "a suspended user" do
      let(:user) { create(:user, :suspended) }

      it_should_deny_all([:admin] + facility_operators)
    end

  end

  describe "unexpire", feature_setting: { create_users: true, reload_routes: true } do
    let(:expired_user) { create(:user, :expired) }
    let(:facility) { create(:facility) }

    describe "as a facility admin" do
      let(:facility_admin) { create(:user, :facility_administrator, facility: facility) }

      it "cannot be accessed" do
        sign_in facility_admin
        patch :unexpire, params: { facility_id: facility.url_name, id: expired_user.id }
        expect(response.code).to eq("403")
        expect(expired_user.reload).to be_expired
      end
    end

    describe "as a global admin" do
      let(:admin) { create(:user, :administrator) }

      it "can mark the user as not expired" do
        sign_in admin
        patch :unexpire, params: { facility_id: facility.url_name, id: expired_user.id }
        expect(expired_user.reload).not_to be_expired
        expect(expired_user).to be_active
      end
    end
  end

  context "orders" do
    before :each do
      @method = :get
      @action = :orders
      @params.merge!(user_id: @guest.id)
    end

    it_should_allow_operators_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:order_details)).to be_kind_of ActiveRecord::Relation
    end
  end

end
