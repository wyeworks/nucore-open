# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ServicesController do
  let(:service) { @service }
  let(:facility) { @authable }
  let(:facility_account) { service.facility_account }

  render_views

  it "routes", :aggregate_failures do
    expect(get: "/#{facilities_route}/alpha/services").to route_to(controller: "services", action: "index", facility_id: "alpha")
    expect(get: "/#{facilities_route}/alpha/services/1/manage").to route_to(controller: "services", action: "manage", id: "1", facility_id: "alpha")
  end

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:setup_facility)
    @service = FactoryBot.create(:service, facility: @authable)
    @service_pp = FactoryBot.create(:service_price_policy, product: @service, price_group: @nupg)
    @params = { facility_id: @authable.url_name }
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only do
      expect(assigns(:products)).to eq([@service])
      expect(response).to be_successful
      expect(response).to render_template("admin/products/index")
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
      @params.merge!(id: @service.url_name)
    end

    include_examples "a purchasable product"
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:product)).to be_kind_of Service
      expect(assigns(:product).facility).to eq(@authable)
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
      @params.merge!(service: FactoryBot.attributes_for(:service, facility_account_id: facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Service
      expect(assigns(:product).facility).to eq(@authable)
      is_expected.to set_flash
      assert_redirected_to [:manage, @authable, assigns(:product)]
    end

    it "does not raise error on blank url name" do
      sign_in @admin
      @params[:service][:url_name] = ""
      do_request
      expect(assigns(:product)).to be_invalid
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(id: @service.url_name, service: FactoryBot.attributes_for(:service, facility_account_id: facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Service
      is_expected.to set_flash
      assert_redirected_to manage_facility_service_url(@authable, assigns(:product))
    end
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
      @params.merge!(id: @service.url_name)
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to eq(@service)
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
      expect(response).to be_successful
      expect(response).to render_template("manage")
    end
  end
end
