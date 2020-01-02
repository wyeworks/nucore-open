# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NuResearchSafety::ProductCertificationRequirement, type: :model do
  context "validations" do
    it { is_expected.to validate_presence_of(:product) }
    it { is_expected.to validate_presence_of(:nu_safety_certificate) }

    context "with an existing requirement" do
      let!(:product_certification_requirement) { FactoryBot.create(:product_certification_requirement) }
      let(:product) { product_certification_requirement.product }
      let(:certificate) { product_certification_requirement.certificate }

      it 'prevents a duplicate requirement for the same product', :aggregate_failures do
        cert_req = product.product_certification_requirements.build(certificate: certificate)
        expect(cert_req).to be_invalid
        expect(cert_req.errors).to be_added(:nu_safety_certificate, :taken)
      end

      it 'does not prevent adding a previously deleted requirement' do
        product_certification_requirement.destroy
        cert_req = product.product_certification_requirements.build(certificate: certificate)
        expect(cert_req).to be_valid
      end
    end
  end
end
