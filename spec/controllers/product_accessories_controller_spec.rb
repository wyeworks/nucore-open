# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ProductAccessoriesController do
  render_views

  before(:all) { create_users }

  let(:instrument) { FactoryBot.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let(:accessory) { FactoryBot.create(:setup_item, facility:) }
  let(:timed_service) { FactoryBot.create(:setup_timed_service, facility:) }

  before :each do
    @authable = facility
    @params = { facility_id: facility.url_name, product_id: instrument.url_name }
  end

  describe "index" do
    let!(:unchosen_accessory) { FactoryBot.create(:setup_item, facility:) }
    let!(:inactive_product) { FactoryBot.create(:setup_item, is_archived: true, facility:) }
    let!(:hidden_product) { FactoryBot.create(:setup_item, is_hidden: true, facility:) }
    let!(:bundle) { FactoryBot.create(:bundle, facility:) }

    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only do
      # success!
    end

    context "with an available accessory" do
      before :each do
        maybe_grant_always_sign_in :admin
        instrument.accessories << accessory
        do_request
      end

      it "has the unchosen accessory in the list" do
        expect(assigns(:available_accessories)).to include(unchosen_accessory)
      end

      it "excludes the already created accessory in the list" do
        expect(assigns(:available_accessories)).not_to include(accessory)
      end

      it "does not include itself" do
        expect(assigns(:available_accessories)).not_to include(instrument)
      end

      it "does not include the bundle" do
        expect(assigns(:available_accessories)).not_to include(bundle)
      end

      it "does not include inactive products" do
        expect(assigns(:available_accessories)).not_to include(inactive_product)
      end

      it "includes hidden products" do
        expect(assigns(:available_accessories)).to include(hidden_product)
      end
    end

    it "only includes active accessories" do
      maybe_grant_always_sign_in :admin
      instrument.accessories << accessory
      ProductAccessory.first.soft_delete
      instrument.accessories << unchosen_accessory
      do_request
      expect(assigns(:product_accessories)).not_to include(accessory)
    end
  end

  describe "create" do
    before do
      @method = :post
      @action = :create
    end

    context "permissions" do
      before do
        @params[:product_accessory] = { accessory_id: timed_service.id, scaling_type: "manual" }
      end

      it_should_allow_managers_and_senior_staff_only(:redirect) {}
    end

    context "success" do
      before do
        maybe_grant_always_sign_in :admin
        @params[:product_accessory] = { accessory_id: accessory.id, scaling_type: "quantity" }
      end

      context "with quantity-based accessory" do
        before do
          expect(instrument.accessories).to be_empty
          do_request
        end

        it "creates the new accessory" do
          expect(instrument.reload.accessories).to eq([accessory])
        end

        it "the new accessory is quantity based" do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq("quantity")
        end

        it "redirects to index" do
          expect(response).to redirect_to(action: :index)
        end
      end

      context "with time-based accessory" do
        before do
          @params[:product_accessory] = { accessory_id: timed_service.id, scaling_type: "auto" }
          do_request
        end

        it "creates the new accessory" do
          expect(instrument.reload.accessories).to eq([timed_service])
        end

        it "sets the new accessory as auto-scaled" do
          expect(instrument.reload.product_accessories.first.scaling_type).to eq("auto")
        end

        it "redirects to index" do
          expect(response).to redirect_to(action: :index)
        end
      end
    end
  end

  describe "destroy" do
    before :each do
      instrument.accessories << accessory
      @method = :delete
      @action = :destroy
      @params.merge! id: instrument.product_accessories.first.id
    end

    it_should_allow_managers_and_senior_staff_only(:redirect) {}

    context "signed in" do
      before :each do
        maybe_grant_always_sign_in :admin
        do_request
      end

      it "soft deletes the accessory" do
        expect(assigns(:product_accessory).deleted_at).to be_present
      end

      it "redirects to index" do
        expect(response).to redirect_to(action: :index)
      end
    end
  end
end
