# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

# NOTE: changed create/new/edit/update from it_should_allow_all facility_operators to
# it_should_allow_managers_only as part of ticket #38481
RSpec.describe BundleProductsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @authable)
    @item = FactoryBot.create(:item, facility_account: @facility_account, facility: @authable)
    @bundle = FactoryBot.create(:bundle, facility_account: @facility_account, facility: @authable)
    @bundle_product = BundleProduct.create!(bundle: @bundle, product: @item, quantity: 1)
  end

  context "index" do
    before(:each) do
      @method = :get
      @action = :index
      @params = { facility_id: @authable.url_name, bundle_id: @bundle.url_name }
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      expect(assigns(:bundle_products)).to all be_kind_of(BundleProduct)
      is_expected.to render_template("index")
    end
  end

  context "create" do
    before(:each) do
      @method = :post
      @action = :create
      item2 = FactoryBot.create(:item, facility_account: @facility_account, facility: @authable)
      @params = {
        facility_id: @authable.url_name,
        bundle_id: @bundle.url_name,
        bundle_product: {
          product_id: item2.id,
          quantity: 2,
        },
      }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      expect(assigns(:bundle_product)).to be_kind_of BundleProduct
      is_expected.to set_flash
      assert_redirected_to facility_bundle_bundle_products_url(@authable, @bundle)
    end
  end

  context "new" do
    before(:each) do
      @method = :get
      @action = :new
      @params = { facility_id: @authable.url_name, bundle_id: @bundle.url_name }
    end

    it_should_require_login

    it_should_allow_managers_only do
      expect(assigns(:bundle_product)).to be_kind_of BundleProduct
      expect(assigns(:bundle_product)).to be_new_record
      is_expected.to render_template("new")
    end
  end

  context "edit" do
    before(:each) do
      @method = :get
      @action = :edit
      @params = { facility_id: @authable.url_name, bundle_id: @bundle.url_name, id: @bundle_product.id }
    end

    it_should_require_login

    it_should_allow_managers_only do
      assert_init_bundle
      is_expected.to render_template("edit")
    end
  end

  context "update" do
    before(:each) do
      @method = :put
      @action = :update
      @params = {
        facility_id: @authable.url_name,
        bundle_id: @bundle.url_name,
        id: @bundle_product.id,
        bundle_product: {
          quantity: 3,
        },
      }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      assert_init_bundle
      expect(assigns(:bundle_product)).to be_kind_of BundleProduct
      expect(@bundle_product.quantity).not_to eq(assigns(:bundle_product).quantity)
      is_expected.to set_flash
      assert_redirected_to facility_bundle_bundle_products_url(@authable, @bundle)
    end
  end

  context "destroy" do
    before(:each) do
      @method = :delete
      @action = :destroy
      @params = { facility_id: @authable.url_name, bundle_id: @bundle.url_name, id: @bundle_product.id }
    end

    it_should_require_login

    it_should_allow_managers_only :redirect do
      assert_init_bundle

      begin
        BundleProduct.find(@bundle_product.id)
        assert false
      rescue ActiveRecord::RecordNotFound
        assert true
      end

      is_expected.to set_flash
      assert_redirected_to facility_bundle_bundle_products_url(@authable, @bundle)
    end
  end

  def assert_init_bundle
    expect(assigns(:bundle)).to_not be_nil
    expect(assigns(:bundle)).to eq(@bundle)
  end
end
