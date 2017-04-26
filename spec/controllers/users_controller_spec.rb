require "rails_helper"
require "controller_spec_helper"

RSpec.describe UsersController do
  render_views

  let(:facility) { FactoryGirl.create(:facility) }

  before(:each) do
    create_users
    @authable = facility
    @params = { facility_id: @authable.url_name }
  end

  context "index" do

    before :each do
      @method = :get
      @action = :index
      @inactive_user = FactoryGirl.create(:user, first_name: "Inactive")

      @active_user = FactoryGirl.create(:user, first_name: "Active")
      place_and_complete_item_order(@active_user, @authable)
      # place two orders to make sure it only and_return the user once
      place_and_complete_item_order(@active_user, @authable)

      @lapsed_user = FactoryGirl.create(:user, first_name: "Lapsed")
      @old_order_detail = place_and_complete_item_order(@lapsed_user, @authable)
      @old_order_detail.order.update_attributes(ordered_at: 400.days.ago)
    end

    it_should_allow_operators_only :success, "include the right users" do
      expect(assigns[:users].size).to eq(1)
      expect(assigns[:users]).to include @active_user
    end

    context "with newly created user" do
      before :each do
        @user = FactoryGirl.create(:user)
        @params.merge!(user: @user.id)
      end
      it_should_allow_operators_only :success, "set the user" do
        expect(assigns[:new_user]).to eq(@user)
      end
    end

  end

  describe "GET #edit", feature_setting: { create_users: true } do
    let(:user) { FactoryGirl.create(:user, :external) }

    before(:each) do
      @method = :get
      @action = :edit
      @params[:id] = user.id
    end

    it_should_allow_admin_only { expect(assigns[:user]).to eq(user) }
  end

  describe "PUT #update", feature_setting: { create_users: true } do
    let(:user) { FactoryGirl.create(:user, :external) }

    before(:each) do
      @method = :put
      @action = :update
      @params[:id] = user.id
      @params[:user] = { first_name: "New", last_name: "Name" }
    end

    it_should_allow_admin_only(:found) do
      expect(user.reload.first_name).to eq("New")
      expect(response).to redirect_to facility_user_path(facility, user)
    end

    context "with bad params" do
      before(:each) do
        @params[:user] = { email: "test@example.com", username: "newusername" }
      end

      it_should_allow_admin_only(:found) do
        expect(user.reload.first_name).to eq(user.first_name)
      end
    end
  end

  describe "GET #access_list" do
    let(:facility) { FactoryGirl.create(:setup_facility) }
    let(:user) { FactoryGirl.create(:user) }
    let!(:instruments) { FactoryGirl.create_list(:instrument_requiring_approval, 2, facility: facility) }
    let!(:services) { FactoryGirl.create_list(:setup_service, 2, requires_approval: true, facility: facility) }
    let!(:training_requests) do
      [
        FactoryGirl.create(:training_request, user: user, product: instruments.last),
        FactoryGirl.create(:training_request, user: user, product: services.first),
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
    context "enabled", feature_setting: { create_users: true } do

      it "routes", :aggregate_failures do
        expect(get: "/#{facilities_route}/url_name/users/new").to route_to(controller: "users", action: "new", facility_id: "url_name")
        expect(post: "/#{facilities_route}/url_name/users").to route_to(controller: "users", action: "create", facility_id: "url_name")
        expect(get: "/#{facilities_route}/url_name/users/new_external").to route_to(controller: "users", action: "new_external", facility_id: "url_name")
        expect(post: "/#{facilities_route}/url_name/users/search").to route_to(controller: "users", action: "search", facility_id: "url_name")
      end

      context "search" do
        let!(:user) { FactoryGirl.create(:user) }

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
            expect(response).to be_success
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
            @user2 = FactoryGirl.build(:user)
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
          expect(assigns(:user)).to be_kind_of User
          expect(assigns(:user)).to be_new_record
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
              @params.merge!(user: FactoryGirl.attributes_for(:user))
            end

            it_should_allow_operators_only :redirect do
              expect(assigns(:user)).to be_kind_of User
              expect(assigns(:user)).to be_persisted
              assert_redirected_to facility_users_url(user: assigns[:user].id)
            end
          end

          context "with missing parameters" do
            before :each do
              @params.merge!(user: {})
            end

            it_should_allow_operators_only do
              expect(assigns(:user)).to be_new_record
              expect(response).to render_template "new_external"
            end
          end

          describe "with extra spaces around the username/email" do
            before do
              @params[:user] = FactoryGirl.attributes_for(:user, username: " email@example.com", email: "email@example.com")
            end

            it_should_allow_operators_only :redirect do
              expect(assigns(:user)).to be_persisted
              expect(assigns(:user).email).to eq("email@example.com")
              expect(assigns(:user).username).to eq("email@example.com")
            end
          end
        end

        context "internal user" do
          before :each do
            sign_in @admin
          end

          context "user already exists" do
            let!(:user) { FactoryGirl.create(:user) }
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
              @ldap_user = FactoryGirl.build(:user)
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

    context "disabled", feature_setting: { create_users: false } do
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
    let(:user) { FactoryGirl.create(:user) }
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

    describe "a deactivated user" do
      before(:each) { user.deactivate }

      it_should_deny_all([:admin] + facility_operators)
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

  context "accounts" do
    before :each do
      @method = :get
      @action = :accounts
      @params.merge!(user_id: @guest.id)
    end

    it_should_allow_operators_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
    end
  end

end
