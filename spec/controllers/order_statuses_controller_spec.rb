# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe OrderStatusesController do
  render_views
  before(:all) { create_users }
  before :each do
    # remove the default ones so they're not in the way
    OrderStatus.delete_all
    expect(OrderStatus.all).to be_empty

    @authable = @facility = FactoryBot.create(:facility)

    @root_status = FactoryBot.create(:order_status)
    expect(@root_status).to be_root
    @root_status2 = FactoryBot.create(:order_status)
    expect(@root_status2).to be_root
    @order_status = FactoryBot.create(:order_status, facility: @facility, parent: @root_status)
    @order_status2 = FactoryBot.create(:order_status, facility: @facility, parent: @root_status)
    expect(OrderStatus.all.size).to eq(4)
    @params = { facility_id: @facility.url_name }
  end

  def self.it_should_disallow_editing_root_statuses
    it "should disallow editing root statuses" do
      expect(@root_status).not_to be_editable
      @params[:id] = @root_status.id
      maybe_grant_always_sign_in :director
      do_request
      expect(response.code).to eq("404")
    end
  end

  context "index" do
    before :each do
      @action = :index
      @method = :get
    end

    it_should_allow_managers_only {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it "should be a success" do
        expect(response).to be_successful
      end
      it "should have all statuses" do
        expect(assigns[:order_statuses]).to contain_all [@root_status, @root_status2, @order_status, @order_status2]
      end
      it "should have the root statuses" do
        expect(assigns[:root_order_statuses]).to contain_all [@root_status, @root_status2]
      end
    end
  end

  context "new" do
    before :each do
      @action = :new
      @method = :get
    end
    it_should_allow_managers_only {}
    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it "should create a new record" do
        expect(assigns[:order_status]).to be_new_record
      end
      it "should set the facility" do
        expect(assigns[:order_status].facility).to eq(@facility)
      end
    end
  end

  context "create" do
    before :each do
      @action = :create
      @method = :post
      @params.merge!(order_status: FactoryBot.attributes_for(:order_status, parent_id: @root_status.id))
    end
    it_should_allow_managers_only(:redirect) {}
    context "signed_in" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      context "success" do
        before :each do
          do_request
        end
        it "should save the record to the database" do
          expect(assigns[:order_status]).not_to be_new_record
        end
        it "should redirect" do
          expect(response).to redirect_to facility_order_statuses_url
        end
        it "should set the flash" do
          is_expected.to set_flash
        end
        it "should save the parent" do
          expect(assigns[:order_status].parent).to eq(@root_status)
        end
        it "should set the facility" do
          expect(assigns[:order_status].facility).to eq(@facility)
        end
      end
      context "failure" do
        context "without name" do
          before :each do
            @params[:order_status][:name] = ""
            do_request
          end
          it "should not save to the database" do
            expect(assigns[:order_status]).to be_new_record
          end
          it "should render new" do
            expect(response).to render_template :new
          end
        end
      end
    end
  end
  context "edit" do
    before :each do
      @action = :edit
      @method = :get
      @params.merge!(id: @order_status.id)
    end
    it_should_allow_managers_only {}
    it_should_disallow_editing_root_statuses
    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :director
        do_request
      end
      it "should set the order status" do
        expect(assigns[:order_status]).to eq(@order_status)
      end
    end
  end

  context "update" do
    before :each do
      @action = :update
      @method = :put
      @params.merge!(id: @order_status.id, order_status: FactoryBot.attributes_for(:order_status, parent_id: @root_status.id))
    end
    it_should_allow_managers_only :redirect
    it_should_disallow_editing_root_statuses
  end

  context "destroy" do
    before :each do
      @action = :destroy
      @method = :delete
      @params.merge!(id: @order_status.id)
    end
    it_should_allow_managers_only(:redirect) {}
    it_should_disallow_editing_root_statuses

    context "signed in" do
      before(:each) { maybe_grant_always_sign_in :director }
      context "success" do
        before :each do
          @user = FactoryBot.create(:user)
          @facility_account = FactoryBot.create(:facility_account, facility: @facility)
          @product = FactoryBot.create(:item, facility: @facility, facility_account: @facility_account)
          @order_details = []
          3.times do
            order_detail = place_product_order(@user, @facility, @product)
            order_detail.change_status! @order_status
            @order_details << order_detail
          end
          do_request
        end
        it "should set the record" do
          expect(assigns[:order_status]).to eq(@order_status)
        end
        it "should destroy the record" do
          expect(assigns[:order_status]).to be_destroyed
        end
        it "should redirect" do
          expect(response).to redirect_to facility_order_statuses_url(facility_id: @facility.url_name)
        end
        it "should set all order details to parent status" do
          @order_details.each { |od| expect(od.reload.order_status).to eq(@root_status) }
        end
      end
    end
  end

end
