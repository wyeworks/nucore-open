# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ProductUsersController do
  render_views

  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility: facility, requires_approval: true) }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :administrator) }
  let(:staff) { create(:user, :staff, facility: facility) }

  describe "index" do
    let!(:user_product) { ProductUser.create(product: instrument, user: user, approved_by: admin.id, approved_at: Time.current) }
    let!(:staff_product) { ProductUser.create(product: instrument, user: staff, approved_by: admin.id, approved_at: Time.current) }

    def do_request
      get :index, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
    end

    it "should only return the two users" do
      sign_in admin
      do_request
      expect(assigns[:product_users]).to contain_exactly(user_product, staff_product)
    end

    it "should return empty and a flash if the product is not restricted" do
      instrument.update_attributes!(requires_approval: false)
      sign_in admin
      do_request

      expect(assigns[:product_users]).to be_nil
      expect(flash[:notice]).not_to be_empty
    end

  end

  describe "create" do
    it "creates and logs a new product user" do
      sign_in staff
      expect {
        post :new, params: {
          facility_id: facility.url_name,
          instrument_id: instrument.url_name,
          user: user,
        }
      }.to change(ProductUser, :count).by(1)
      log_event = LogEvent.find_by(loggable: ProductUser.reorder(:id).last, event_type: :create)
      expect(log_event).to be_present
    end
  end

  describe "update_restrictions" do
    let(:level) { create(:product_access_group, product: instrument) }
    let(:level2) { create(:product_access_group, product: instrument) }

    let!(:user_product) { create(:product_user, product: instrument, user: user, approved_by_user: admin) }
    let!(:staff_product) { create(:product_user, product: instrument, user: staff, approved_by_user: admin) }

    it "updates the product_users" do
      sign_in staff
      put :update_restrictions, params: {
        facility_id: facility.url_name,
        instrument_id: instrument.url_name,
        instrument: {
          product_users: {
            user_product.id => { product_access_group_id: level.id },
            staff_product.id => { product_access_group_id: level2.id },
          },
        },
      }

      expect(user_product.reload.product_access_group).to eq(level)
      expect(staff_product.reload.product_access_group).to eq(level2)
      expect(flash[:notice]).to be_present
    end
  end

  describe "destroy" do
    let!(:user_product) { create(:product_user, product: instrument, user: user, approved_by_user: admin) }

    it "destroys the association" do
      sign_in staff
      expect do
        delete :destroy, params: {
          facility_id: facility.url_name,
          instrument_id: instrument.url_name,
          id: user,
        }
      end.to change(ProductUser, :count).by(-1)
      expect(flash[:notice]).to be_present
    end

    it "logs the user product" do
      expect do
        delete :destroy, params: {
          facility_id: facility.url_name,
          instrument_id: instrument.url_name,
          id: user,
        }
        log_event = LogEvent.find_by(loggable: user_product, event_type: :delete)
        expect(log_event).to be_present
      end
    end

    it "does not error if the association is not found" do
      sign_in staff

      delete :destroy, params: {
        facility_id: facility.url_name,
        instrument_id: instrument.url_name,
        id: admin,
      }
      expect(flash[:notice]).to be_present
    end
  end
end
