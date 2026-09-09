# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailStoredFilesController do
  let(:user) { order_detail.user }

  describe "downloading order files", feature_setting: { granular_permissions: true } do
    let(:facility) { product.facility }
    let(:product) { create(:setup_service) }
    let(:order_detail) { create(:purchased_order, product:).order_details.first }
    let(:user) { create(:user) }
    let(:params) { { order_id: order_detail.order_id, order_detail_id: order_detail.id } }

    let!(:permission) { create(:facility_user_permission, user:, facility:, read_access: true) }

    before { sign_in user }

    { sample_results: "sample_result", template_results: "template_result" }.each do |action, file_type|
      describe "##{action}" do
        subject(:download) { get action, params: params.merge(id: file.id) }

        let(:file) { create(:stored_file, :results, order_detail:, file_type:) }

        it "downloads with read_access" do
          download
          expect(response).to redirect_to(file.download_url)
        end

        it "denies access without facility permissions" do
          permission.destroy!
          expect { download }.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    describe "#sample_results_zip" do
      subject(:download) { get :sample_results_zip, params: params.merge(format: :zip) }

      let!(:file) { create(:stored_file, :results, order_detail:) }

      it "downloads the results as a ZIP with read_access" do
        download
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/zip")
        Zip::File.open_buffer(response.body) do |zip|
          expect(zip.map(&:name)).to eq([file.name])
          expect(zip.first.get_input_stream.read).to eq("c,s,v")
        end
      end

      it "denies access without facility permissions" do
        permission.destroy!
        expect { download }.to raise_error(CanCan::AccessDenied)
      end

      it "denies access with read_access in another facility" do
        permission.update!(facility: create(:facility))
        expect { download }.to raise_error(CanCan::AccessDenied)
      end

      it "denies access with the feature disabled", feature_setting: { granular_permissions: false } do
        expect { download }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "order form authorization", feature_setting: { granular_permissions: true } do
    let(:product) { create(:setup_service, :with_order_form) }
    let(:order_detail) { create(:setup_order, product:).order_details.first }
    let(:user) { create(:user) }
    let(:params) { { order_id: order_detail.order_id, order_detail_id: order_detail.id } }

    before do
      create(:facility_user_permission, user:, facility: product.facility, read_access: true)
      sign_in user
    end

    it "denies the upload form with only read_access" do
      expect { get :order_file, params: }.to raise_error(CanCan::AccessDenied)
    end

    it "denies uploading with only read_access" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "files", "template1.txt"))
      expect { post :upload_order_file, params: params.merge(stored_file: { file: }) }.to raise_error(CanCan::AccessDenied)
    end

    it "denies removing files with only read_access" do
      file = create(:stored_file, :results, order_detail:, file_type: "template_result")
      expect { get :remove_order_file, params: }.to raise_error(CanCan::AccessDenied)
      expect(file.reload).to be_persisted
    end
  end

  describe "#remove_order_file" do
    let(:product) { create(:setup_service, :with_order_form) }
    let(:order_detail) { create(:setup_order, product:).order_details.first }
    let!(:file) { create(:stored_file, :results, order_detail:, file_type: "template_result") }

    before { sign_in user }

    it "allows the owner to remove an unpurchased order file" do
      expect do
        get :remove_order_file, params: { order_id: order_detail.order_id, order_detail_id: order_detail.id }
      end.to change { order_detail.stored_files.count }.from(1).to(0)
      expect(response).to redirect_to(order_path(order_detail.order))
    end
  end

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
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "files", "template1.txt"))
      post :upload_order_file, params: params.merge(stored_file: { file: file })
      expect(order_detail.stored_files.count).to eq(1)
    end

    it "gets an error if there is no file" do
      post :upload_order_file, params: params

      error_options = SettingsHelper.feature_on?(:active_storage) ? { validator_type: :attached } : {}

      expect(assigns(:file).errors).to be_added(:file, :blank, error_options)
    end
  end
end
