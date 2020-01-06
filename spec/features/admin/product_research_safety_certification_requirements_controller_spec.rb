# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Certificates" do

  let(:product) { FactoryBot.create(:setup_item) }
  let(:facility) { product.facility }
  let(:staff_member) { FactoryBot.create(:user, :staff, facility: facility) }

  before { login_as staff_member } # should this be a different access level?

  describe "adding a new certification requirement" do
    let!(:certificate) { FactoryBot.create(:research_safety_certificate) }
    let!(:other_certificate) { FactoryBot.create(:research_safety_certificate) }

    it "adds the certification requirement" do
      visit manage_facility_item_path(facility, product)
      click_link "Certification Requirements"
      select other_certificate.name, from: ProductResearchSafetyCertificationRequirement.model_name.human
      click_button "Add Certification Requirement"

      expect(current_path).to eq(facility_product_product_research_safety_certification_requirements_path(facility, product))
      expect(page).to have_content("Certification requirement #{other_certificate.name} added")
    end

    it "does not display certificates in dropdown that have already been added", :aggregate_failures do
      FactoryBot.create(:product_certification_requirement, research_safety_certificate: certificate, product: product)
      visit facility_product_product_research_safety_certification_requirements_path(facility, product)

      within '#new_product_research_safety_certification_requirement' do
        expect(page).to have_selector('option', text: other_certificate.name)
        expect(page).not_to have_selector('option', text: certificate.name)
      end
    end
  end

  describe "deleting a certification requirement", :aggregate_failures do
    let!(:certificate) { FactoryBot.create(:research_safety_certificate) }
    let!(:product_certification_requirement) { FactoryBot.create(:product_certification_requirement, research_safety_certificate: certificate, product: product) }

    before do
      visit facility_product_product_research_safety_certification_requirements_path(facility, product)
      click_link "Remove"
    end

    it "deletes the certification requirement", :aggregate_failures do
      expect(current_path).to eq(facility_product_product_research_safety_certification_requirements_path(facility, product))
      expect(page).to have_content("Certification requirement #{certificate.name} removed")
    end

    it "soft-deletes the certification requirement and sets deleted_by_id", :aggregate_failures do
      expect(product_certification_requirement.reload.deleted_at).not_to be_nil
      expect(product_certification_requirement.reload.deleted_by_id).to eq staff_member.id
    end
  end

  describe "with no certificates configured" do
    it "does not have the link" do
      visit manage_facility_item_path(facility, product)
      expect(page).not_to have_link("Certification Requirements")
    end
  end
end
