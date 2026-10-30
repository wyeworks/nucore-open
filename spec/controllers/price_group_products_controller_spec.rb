# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe PriceGroupProductsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:setup_facility)
    @product = FactoryBot.create(:instrument, facility: @authable)
    create_price_group_products
    @params = { facility_id: @authable.url_name, id: @product.url_name }
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    # Edit is really a view/show, so all operators can view, but
    # only the managers can submit
    it_should_allow_operators_only do
      assert_init_price_group_products
      is_expected.to render_template "edit"
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update

      PriceGroup.all.each do |pg|
        @params.merge!(pg_key(pg) => { reservation_window: 5, purchase: "1" })
      end
    end

    it_should_allow_managers_only :redirect, "to update existing PriceGroupProducts" do
      assert_init_price_group_products
      expect(PriceGroupProduct.count).to eq(PriceGroup.count)
      @price_group_products.each { |pgp| expect(pgp.reload.reservation_window).to eq(5) }
      assert_successful_update
    end

    it "should remove PriceGroupProduct when a PriceGroup cannot purchase" do
      pg = PriceGroup.first
      @params[pg_key(pg)] = nil
      expect(PriceGroupProduct.count).to eq(PriceGroup.count)
      maybe_grant_always_sign_in :director
      do_request
      expect(PriceGroupProduct.count).to eq(PriceGroup.count - 1)
      assert_successful_update
    end

    it "should create PriceGroupProducts when a PriceGroup can purchase" do
      pgp = @price_group_products.first
      pgp.destroy
      expect(PriceGroupProduct.count).to eq(PriceGroup.count - 1)
      maybe_grant_always_sign_in :director
      do_request
      expect(PriceGroupProduct.count).to eq(PriceGroup.count)
      assert_successful_update
    end

    it "should error if no reservation window given on instrument" do
      pg = PriceGroup.first
      @params[pg_key(pg)][:reservation_window] = ""
      maybe_grant_always_sign_in :director
      do_request
      expect(flash[:notice]).to be_nil
      expect(flash[:error]).not_to be_nil
      assert_update_redirect
    end

    it "should not error if no reservation window given on non-instrument" do
      @product = FactoryBot.create(:item, facility: @authable)
      create_price_group_products
      pg = @price_group_products.first.price_group
      @params[pg_key(pg)][:reservation_window] = ""
      @params[:id] = @product.url_name
      maybe_grant_always_sign_in :director
      do_request
      assert_successful_update
    end
  end

  private

  def pg_key(price_group)
    "price_group_#{price_group.id}".to_sym
  end

  def create_price_group_products
    @price_group_products = []

    PriceGroup.all.each do |pg|
      price_group_product = PriceGroupProduct.find_or_create_by(price_group_id: pg.id, product_id: @product.id)

      if @product.is_a? Instrument
        price_group_product.reservation_window = 14
        assert price_group_product.save
      end

      @price_group_products << price_group_product
    end
  end

  def assert_update_redirect
    assert_redirected_to edit_facility_price_group_product_path(@authable, @product)
  end

  def assert_successful_update
    expect(flash[:notice]).not_to be_nil
    expect(flash[:error]).to be_nil
    assert_update_redirect
  end

  def assert_init_price_group_products
    expect(assigns[:product]).to eq(@product)
    expect(assigns[:is_instrument]).to eq(@product.is_a?(Instrument))
    PriceGroup.all.each { |pg| expect(assigns[:price_groups]).to be_include pg }
    @price_group_products.each { |pgp| expect(assigns[:price_group_products]).to be_include pgp }
    expect(assigns[:price_group_products]).to be_include assigns[:price_group_product]
  end
end
