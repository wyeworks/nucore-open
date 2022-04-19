# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

def fixture_file(filename)
  Rack::Test::UploadedFile.new(
    "#{Rails.root}/spec/files/order_imports/#{filename}",
    "text/csv",
  )
end

RSpec.describe OrderImportsController do
  let(:facility) { create(:facility) }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @params = { facility_id: facility.url_name }
  end

  context "starting an import" do
    before :each do
      @action = :new
      @method = :get
    end

    it_should_allow_managers_only do
      expect(assigns :order_import).to be_new_record
      is_expected.to render_template "new"
    end
  end

  context "importing orders" do
    before :each do
      @action = :create
      @method = :post
      @params.merge!(
        order_import: {
          upload_file: upload_file,
          fail_on_error: fail_on_error,
          send_receipts: send_receipts,
        },
      )
    end

    context "when the file is blank" do
      let(:upload_file) { fixture_file("blank.csv") }
      let(:fail_on_error) { false }
      let(:send_receipts) { false }

      it_should_allow_managers_only(:redirect) do
        expect(flash[:error]).to be_blank
        expect(flash[:notice]).to be_present
        is_expected.to redirect_to new_facility_order_import_url
      end

      context "when a director is signed in" do
        before(:each) { maybe_grant_always_sign_in :director }

        it "creates one OrderImport record" do
          expect { do_request }.to change(OrderImport, :count).from(0).to(1)
        end

        it "creates one StoredFile record" do
          expect { do_request }.to change(StoredFile, :count).from(0).to(1)
        end
      end
    end
  end

  describe "downloading an error file" do
    let(:stored_file) { FactoryBot.create(:csv_stored_file) }
    let!(:order_import) do
      OrderImport.create!(
        created_by: @director.id,
        upload_file: stored_file,
        error_file: stored_file,
        facility: facility,
      )
    end

    before do
      @action = :error_report
      @method = :get
      @params.merge!(id: order_import.id)
    end

    it_should_allow_managers_only(:redirect) do
      is_expected.to redirect_to order_import.error_file_download_url
    end
  end
end
