# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailStoredFilesController do
  let(:user) { order_detail.user }

  describe "#order_file" do
    let(:product) { create(:setup_service, :with_order_form) }
    let(:order_detail) { order.order_details.first }
    let(:facility) { order.facility }

    let(:params) { { order_id: order.id, order_detail_id: order_detail.id } }
    before { sign_in user }

    describe "while in the cart" do
      let(:order) { create(:setup_order, product: product) }

      it "has access" do
        get :order_file, params: params
        expect(response).to be_successful
      end
    end

    describe "adding to an existing order" do
      let(:order) { create(:purchased_order, product: product) }
      let(:user) { create(:user, :staff, facility: facility) }
      let(:merge_order) { create(:merge_order, merge_with_order: order) }

      it "has access" do
        get :order_file, params: { order_id: merge_order.id, order_detail_id: merge_order.order_details.first.id }
        expect(response).to be_successful
      end
    end
  end

  describe "#upload_order_file" do
    let(:product) { create(:setup_service, :with_order_form) }
    let(:order_detail) { order.order_details.first }
    let(:facility) { order.facility }
    let(:order) { create(:setup_order, product: product) }

    let(:params) { { order_id: order.id, order_detail_id: order_detail.id } }
    before { sign_in user }

    it "can upload the file" do
      file = fixture_file_upload(Rails.root.join("spec", "files", "template1.txt"))
      post :upload_order_file, params: params.merge(stored_file: { file: file })
      expect(order_detail.stored_files.count).to eq(1)
    end

    it "gets an error if there is no file" do
      post :upload_order_file, params: params
      expect(assigns(:file).errors).to be_added(:file, :blank)
    end
  end
end
