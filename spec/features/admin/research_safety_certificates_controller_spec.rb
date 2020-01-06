# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Research Safety Certificates" do
  before { login_as administrator }

  let(:administrator) { FactoryBot.create(:user, :administrator) }
  let!(:certificate) { FactoryBot.create(:research_safety_certificate) }

  describe "adding a new certificate" do
    before do
      visit research_safety_certificates_path
      click_link "Add Certificate"
      fill_in "research_safety_certificate[name]", with: "Test"
      click_button "Create Certificate"
    end

    it "adds the certificate" do
      expect(current_path).to eq research_safety_certificates_path
      expect(page).to have_content("Certificate Test created")
    end
  end

  describe "editing a certificate", :aggregate_failures do
    before do
      visit research_safety_certificates_path
      click_link "Edit Certificate"
      fill_in "research_safety_certificate[name]", with: "Edited-#{certificate.id}"
      click_button "Update Certificate"
    end

    it "updates the certificate" do
      expect(current_path).to eq research_safety_certificates_path
      expect(page).to have_content("Certificate Edited-#{certificate.id} updated")
    end
  end

  describe "deleting a certificate", :aggregate_failures do
    before do
      visit research_safety_certificates_path
      click_link "Remove"
    end

    it "deletes the certificate", :aggregate_failures do
      expect(current_path).to eq research_safety_certificates_path
      expect(page).to have_content("Certificate #{certificate.name} removed")
    end

    it "soft-deletes the certificate and sets deleted_by_id", :aggregate_failures do
      expect(certificate.reload.deleted_at).not_to be_nil
      expect(certificate.reload.deleted_by_id).to eq administrator.id
    end
  end
end
