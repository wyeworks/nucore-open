# frozen_string_literal: true

require "rails_helper"

RSpec.describe "submissions" do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let(:service) { create(:setup_service, facility:) }
  let(:order_detail) { create(:purchased_order, product: service).order_details.first }
  let(:admin) { create(:user, :administrator) }

  describe "submission show" do
    let(:submission) { create(:sanger_sequencing_submission, sample_count: 2, order_detail:) }

    before do
      login_as admin
    end

    it "does not show primers if needs primers is disabled for the service" do
      visit sanger_sequencing_submission_path(submission)

      expect(submission.product.sanger_product&.needs_primer).to be_falsy
      expect(page).to have_content("Submission ##{submission.id}")
      expect(page).to_not have_content("Primer")
    end

    it "shows primer column if service needs primer" do
      service.create_sanger_product(needs_primer: true)

      visit sanger_sequencing_submission_path(submission)

      expect(page).to have_content("Submission ##{submission.id}")
      expect(page).to have_content("Primer")
    end
  end
end
