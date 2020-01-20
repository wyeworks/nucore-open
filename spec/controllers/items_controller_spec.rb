# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ItemsController do
  let(:item) { @item }
  let(:facility) { @authable }
  let(:facility_account) { item.facility_account }

  render_views

  it "should route" do
    expect(get: "/#{I18n.t('facilities_downcase')}/url_name/items").to route_to(controller: "items", action: "index", facility_id: "url_name")
    expect(get: "/#{I18n.t('facilities_downcase')}/url_name/items/1").to route_to(controller: "items", action: "show", facility_id: "url_name", id: "1")
  end

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:setup_facility)
    @item = FactoryBot.create(:item, facility: @authable)
    @item_pp = FactoryBot.create(:item_price_policy, product: item, price_group: @nupg)
    @params = { facility_id: @authable.url_name, id: @item.url_name }
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
      @params.delete(:id)
    end

    it_should_allow_operators_only do |_user|
      expect(assigns(:products)).to eq([@item])
      expect(response).to be_successful
      expect(response).to render_template("admin/products/index")
    end
  end

  context "manage" do
    before :each do
      @method = :get
      @action = :manage
    end

    it_should_allow_operators_only do |_user|
      expect(assigns[:product]).to eq(@item)
      expect(response).to be_successful
      expect(response).to render_template("manage")
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
    end

    include_examples "a purchasable product"
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:product)).to be_kind_of Item
      is_expected.to render_template "new"
    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    it_should_allow_managers_only do
      is_expected.to render_template "edit"
    end
  end

  context "create" do
    before :each do
      @method = :post
      @action = :create
      @params.merge!(item: FactoryBot.attributes_for(:item, facility_account_id: facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      is_expected.to set_flash
      assert_redirected_to [:manage, @authable, assigns(:product)]
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(item: FactoryBot.attributes_for(:item, facility_account_id: facility_account.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      expect(assigns(:product)).to eq(@item)
      is_expected.to set_flash
      assert_redirected_to manage_facility_item_url(@authable, assigns(:product))
    end
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Item
      should_be_destroyed @item
      assert_redirected_to facility_items_url
    end
  end
end
