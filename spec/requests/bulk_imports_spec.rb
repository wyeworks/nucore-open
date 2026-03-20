# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bulk imports" do
  let(:admin) { create(:user, :administrator) }
  let(:import_type) { "some import type" }

  before do
    allow(BulkImport).to receive(:import_types) do
      [import_type]
    end
  end

  shared_examples "require login" do
    it "redirects to login page" do
      action.call

      expect(response).to have_http_status(:found)
      expect(response.location).to eq(new_user_session_url)
    end
  end

  describe "new" do
    let(:action) do
      -> { get new_bulk_import_path }
    end

    it_behaves_like "require login"

    context "with admin user" do
      before { login_as(admin) }

      it "renders form" do
        action.call

        expect(page).to have_field("bulk_import[import_type]")
        expect(page).to have_field("bulk_import[file]")
      end
    end
  end

  describe "show" do
    let(:bulk_import) do
      BulkImport.create(
        import_type:,
        created_by: admin,
      )
    end
    let(:action) do
      -> { get bulk_import_path(bulk_import) }
    end

    it_behaves_like "require login"

    context "with admin user" do
      before { login_as admin }

      it "shows bulk import information" do
        action.call

        expect(page).to have_content("Bulk Import #{bulk_import.id}")
      end
    end
  end

  context "index" do
    let!(:bulk_import) do
      BulkImport.create(
        import_type:,
        created_by: admin,
      )
    end
    let(:action) do
      -> { get bulk_imports_path }
    end

    it_behaves_like "require login"

    context "with admin user" do
      before { login_as admin }

      it "list bulk imports" do
        action.call

        expect(page).to have_content("Bulk Imports")
        expect(page).to have_link(href: bulk_import_path(bulk_import))
      end
    end
  end

  describe "create" do
    let(:file) do
      Tempfile.create.tap do |file|
        file.write(
          <<~CSV
            Col1,Col2
            val1,val2
          CSV
        )
      end
    end
    let(:params) do
      {
        bulk_import: {
          import_type:,
          file: Rack::Test::UploadedFile.new(file.path, "text/csv"),
        }
      }
    end
    let(:action) do
      -> { post bulk_imports_path, params: }
    end

    after do
      File.unlink(file.path) if file
    end

    it_behaves_like "require login"

    context "with admin user" do
      before { login_as(admin) }

      it "creates a bulk_import record" do
        expect { action.call }.to change(BulkImport, :count).by(1)
      end

      it "redirects to show on success" do
        action.call

        expect(response).to have_http_status(:found)
        expect(response.location).to eq(bulk_imports_url)
      end

      it "enqueues an import job" do
        expect do
          action.call
        end.to(
          enqueue_job(BulkImportJob)
          .with(an_instance_of(BulkImport))
        )
      end
    end

    context "when file is blank" do
      let(:params) do
        { bulk_import: { import_type: "some_type" } }
      end

      before { sign_in admin }

      it "returns bad request" do
        action.call

        expect(response).to have_http_status(:bad_request)
      end

      it "renders an error" do
        action.call

        expect(page).to have_content("File must be present")
      end

      it "does not create a record" do
        expect { action.call }.not_to(
          change(BulkImport, :count)
        )
      end
    end
  end
end
