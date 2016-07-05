require "rails_helper"
require "controller_spec_helper"

RSpec.describe ServicesController do
  let(:service) { @service }
  let(:facility) { @authable }

  render_views

  it "routes", :aggregate_failures do
    expect(get: "/#{facilities_route}/alpha/services").to route_to(controller: "services", action: "index", facility_id: "alpha")
    expect(get: "/#{facilities_route}/alpha/services/1/manage").to route_to(controller: "services", action: "manage", id: "1", facility_id: "alpha")
  end

  before(:all) { create_users }

  before(:each) do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @service          = @authable.services.create(FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
    @service_pp       = @service.service_price_policies.create(FactoryGirl.attributes_for(:service_price_policy, price_group: @nupg))
    @params = { facility_id: @authable.url_name }
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only do
      expect(assigns(:products)).to eq([@service])
      expect(response).to be_success
      expect(response).to render_template("admin/products/index")
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
      @params.merge!(id: @service.url_name)
    end

    it "should allow public access" do
      do_request
      expect(assigns[:service]).to eq(@service)
      expect(response).to be_success
      expect(response).to render_template("services/show")
    end

    it_should_allow_all facility_users do
      expect(assigns[:service]).to eq(@service)
      expect(response).to be_success
      expect(response).to render_template("services/show")
    end

    it "should fail without a valid account" do
      sign_in @guest
      do_request
      expect(flash).not_to be_empty
      expect(assigns[:add_to_cart]).to be false
      expect(assigns[:error]).to eq("no_accounts")
    end

    context "when the service requires approval" do
      before(:each) do
        add_account_for_user(:guest, service)
        service.update_attributes(requires_approval: true)
      end

      context "if the user is not approved" do
        before(:each) do
          sign_in @guest
          do_request
        end

        context "if the training request feature is enabled", feature_setting: { training_requests: true } do
          it "gives the user the option to submit a request for approval" do
            expect(assigns[:add_to_cart]).to be_blank
            assert_redirected_to(new_facility_product_training_request_path(facility, service))
          end
        end

        context "if the training request feature is disabled", feature_setting: { training_requests: false } do
          it "denies access to the user" do
            expect(assigns[:add_to_cart]).to be_blank
            expect(flash[:notice]).to include("service requires approval")
          end
        end
      end

      it "should not show a notice and show an add to cart" do
        @product_user = ProductUser.create(product: @service, user: @guest, approved_by: @admin.id, approved_at: Time.zone.now)
        add_account_for_user(:guest, @service, @nupg)
        sign_in @guest
        do_request
        expect(flash).to be_empty
        expect(assigns[:add_to_cart]).to be true
      end

      context "when the user is an admin" do
        before(:each) do
          add_account_for_user(:admin, service)
          sign_in @admin
          do_request
        end

        it "adds the service to the cart" do
          expect(assigns[:add_to_cart]).to be true
        end
      end
    end

    context "hidden service" do
      before :each do
        @service.update_attributes(is_hidden: true)
      end

      it_should_allow_operators_only do
        expect(response).to be_success
      end

      it "should show the page if you're acting as a user" do
        allow_any_instance_of(ServicesController).to receive(:acting_user).and_return(@guest)
        allow_any_instance_of(ServicesController).to receive(:acting_as?).and_return(true)
        sign_in @admin
        do_request
        expect(response).to be_success
        expect(assigns[:service]).to eq(@service)
      end
    end
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:service)).to be_kind_of Service
      expect(assigns(:service).facility).to eq(@authable)
    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
      @params.merge!(id: @service.url_name)
    end

    it_should_allow_managers_only do
      is_expected.to render_template "edit"
    end
  end

  context "create" do
    before :each do
      @method = :post
      @action = :create
      @params.merge!(service: FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:service)).to be_kind_of Service
      expect(assigns(:service).facility).to eq(@authable)
      is_expected.to set_flash
      assert_redirected_to [:manage, @authable, assigns(:service)]
    end

    it "does not raise error on blank url name" do
      sign_in @admin
      @params[:service][:url_name] = ""
      do_request
      expect(assigns(:service)).to be_invalid
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(id: @service.url_name, service: FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:service)).to be_kind_of Service
      is_expected.to set_flash
      assert_redirected_to manage_facility_service_url(@authable, assigns(:service))
    end
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
      @params.merge!(id: @service.url_name)
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:service)).to eq(@service)
      should_be_destroyed @service
      assert_redirected_to facility_services_url
    end
  end

  context "manage" do
    before :each do
      @method = :get
      @action = :manage
      @params = { id: @service.url_name, facility_id: @authable.url_name }
    end

    it_should_allow_operators_only do
      expect(response).to be_success
      expect(response).to render_template("services/manage")
    end
  end
end
