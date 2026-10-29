# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe BundlesController do
  let(:bundle) { @bundle }
  let(:facility) { @authable }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @authable)
    @bundle = FactoryBot.create(:bundle, facility_account: @facility_account, facility: @authable)

    # Create at least one item in the bundle, otherwise bundle.can_purchase? will return false
    item = FactoryBot.create(:item, facility_account: @facility_account, facility: @authable)
    item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group: @nupg))
    bundle_product = BundleProduct.new(bundle: @bundle, product: item, quantity: 1)
    bundle_product.save!
  end

  context "index" do
    before(:each) do
      @method = :get
      @action = :index
      @params = { facility_id: @authable.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      expect(assigns(:archived_product_count)).to be_kind_of Integer
      expect(assigns(:not_archived_product_count)).to be_kind_of Integer
      expect(assigns(:products).size).to eq(1)
      expect(assigns(:products)).to eq(@authable.bundles.not_archived)
    end

    it "should show archived facilities" do
      @bundle.is_archived = true
      assert @bundle.save
      maybe_grant_always_sign_in(:director)
      @params[:archived] = "true"
      do_request
      expect(assigns(:products).size).to eq(1)
      expect(assigns(:products)).to eq(@authable.bundles.archived)
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
      @params = { facility_id: @authable.url_name, id: @bundle.url_name }
    end

    include_examples "a purchasable product"
  end

  context "new" do
    before(:each) do
      @method = :get
      @action = :new
      @params = { facility_id: @authable.url_name }
    end

    it_should_require_login

    it_should_allow_managers_only do
      expect(assigns(:product)).to be_kind_of Bundle
      expect(assigns(:product)).to be_new_record
      is_expected.to render_template("new")
    end
  end

  context "edit" do
    before(:each) do
      @method = :get
      @action = :edit
      @params = { facility_id: @authable.url_name, id: @bundle.url_name }
    end

    it_should_require_login

    it_should_allow_managers_only do
      assert_init_bundle
      is_expected.to render_template("edit")
    end
  end

  context "create" do
    before(:each) do
      @method = :post
      @action = :create
      @params = { facility_id: @authable.url_name, bundle: FactoryBot.attributes_for(:bundle) }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Bundle
      expect(assigns(:product).initial_order_status_id).to eq(OrderStatus.default_order_status.id)
      expect(assigns(:product).requires_approval).to eq(false)
      expect(assigns(:product)).to be_persisted
      is_expected.to set_flash
      assert_redirected_to [:manage, @authable, assigns(:product)]
    end
  end

  context "update" do
    before(:each) do
      @method = :put
      @action = :update
      @params = {
        facility_id: @authable.url_name,
        id: @bundle.url_name,
        bundle: FactoryBot.attributes_for(:bundle, url_name: @bundle.url_name),
      }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      assert_init_bundle
      is_expected.to set_flash
      assert_redirected_to manage_facility_bundle_url(@authable, @bundle)
    end
  end

  def assert_init_bundle
    expect(assigns(:product)).to_not be_nil
    expect(assigns(:product)).to eq(@bundle)
  end
end
