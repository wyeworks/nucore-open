# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Certificates" do
  before { login_as staff_member } # should this be a different access level?

  let(:staff_member) { FactoryBot.create(:user, :staff, facility: facility) }
  let(:product_certification_requirement) { FactoryBot.create(:product_certification_requirement) }
  let(:certificate) { product_certification_requirement.certificate }
  let!(:other_certificate) { FactoryBot.create(:certificate) }
  let!(:extra_certificate) { FactoryBot.create(:certificate) }
  let(:product) { product_certification_requirement.product }
  let(:facility) { product.facility }
  let(:product_certification_index) do
    facility_product_product_certification_requirements_path(facility, product)
  end

  describe "adding a new certification requirement" do
    it "adds the certification requirement" do
      visit product_certification_index
      select other_certificate.name, from: NuResearchSafety::ProductCertificationRequirement.model_name.human
      click_button "Add Certification Requirement"

      expect(current_path).to eq product_certification_index
      expect(page).to have_content("Certification requirement #{other_certificate.name} added")
    end

    it "does not display certificates in dropdown that have already been added", :aggregate_failures do
      visit product_certification_index
      within '#new_nu_research_safety_product_certification_requirement' do
        expect(page).to have_selector('option', text: other_certificate.name)
        expect(page).not_to have_selector('option', text: certificate.name)
      end
    end
  end

  describe "deleting a certification requirement", :aggregate_failures do
    before do
      visit product_certification_index
      click_link "Remove"
    end

    it "deletes the certification requirement", :aggregate_failures do
      expect(current_path).to eq product_certification_index
      expect(page).to have_content("Certification requirement #{certificate.name} removed")
    end

    it "soft-deletes the certification requirement and sets deleted_by_id", :aggregate_failures do
      expect(product_certification_requirement.reload.deleted_at).not_to be_nil
      expect(product_certification_requirement.reload.deleted_by_id).to eq staff_member.id
    end
  end
end
