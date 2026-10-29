# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe AffiliatesController do
  render_views

  before(:all) { create_users }
  before(:each) { @authable = create(:facility) }

  context "GET #index" do
    before do
      @method = :get
      @action = :index
    end

    it_should_allow_admin_only do
      is_expected.to render_template :index
    end
  end

  context "GET #new" do
    before do
      @method = :get
      @action = :new
    end

    it_should_allow_admin_only do
      expect(assigns(:affiliate)).to be_kind_of Affiliate
      expect(assigns(:affiliate)).to be_new_record
      is_expected.to render_template :new
    end
  end

  context "POST #create" do
    before do
      @method = :post
      @action = :create
      @params = { affiliate: { name: "Chik-Fil-A" } }
    end

    it_should_allow_admin_only :redirect do
      is_expected.to set_flash
      expect(assigns(:affiliate)).not_to be_new_record
      expect(assigns(:affiliate).name).to eq(@params[:affiliate][:name])
      assert_redirected_to affiliates_path
    end

    it("fails gracefully if bad attributes posted") do
      bad_attrs_test(:new) { expect(assigns(:affiliate)).to be_new_record }
    end
  end

  context "with id param" do
    before do
      @affiliate = Affiliate.find_or_create_by(name: "CTA")
      @params = { id: @affiliate.id }
    end

    context "GET #edit" do
      before do
        @method = :get
        @action = :edit
      end

      it_should_allow_admin_only do
        expect(assigns(:affiliate)).to eq(@affiliate)
        is_expected.to render_template :edit
      end

      it("fails gracefully when given a bad id") { bad_id_test }
    end

    context "PUT #update" do
      before do
        @method = :put
        @action = :update
        @params.merge!(affiliate: { name: "fugly.com" })
      end

      it_should_allow_admin_only :redirect do
        is_expected.to set_flash
        expect(assigns(:affiliate).name).to eq(@params[:affiliate][:name])
        assert_redirected_to affiliates_path
      end

      it("fails gracefully if given a bad id") { bad_id_test }

      it("fails gracefully when posting bad attributes") { bad_attrs_test :edit }
    end

    context "DELETE #destroy" do
      before do
        @method = :delete
        @action = :destroy
      end

      it_should_allow_admin_only :redirect do
        should_be_destroyed @affiliate
        is_expected.to set_flash
        assert_redirected_to affiliates_path
      end

      it("fails gracefully if given a bad id") { bad_id_test }
    end
  end

  def bad_id_test
    @params[:id] = "98765423456"
    maybe_grant_always_sign_in :admin
    do_request
    is_expected.to set_flash
    assert_redirected_to affiliates_path
  end

  def bad_attrs_test(template)
    @params[:affiliate][:name] = nil
    maybe_grant_always_sign_in :admin
    do_request
    yield if block_given?
    expect(assigns(:affiliate).name).to be_blank
    is_expected.to render_template template
  end
end
