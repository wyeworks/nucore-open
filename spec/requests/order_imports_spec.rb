# frozen_string_literal: true

require "rails_helper"

RSpec.describe "order imports" do
  describe "new" do
    describe "history" do
      let(:facility) { create(:setup_facility) }
      let!(:order_import) { create(:order_import, facility:) }

      before { login_as create(:user, :administrator) }

      it "shows uploaded file url" do
        get new_facility_order_import_path(facility)

        expect(page).to have_text("Import History")
        expect(page).to have_link(order_import.upload_file.name)
      end
    end
  end
end
