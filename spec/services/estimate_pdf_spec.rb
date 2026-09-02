# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimatePdf do
  before do
    skip("Estimate Pdf not defined") unless EstimatePdfFactory.defined?
  end

  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_item, facility:) }
  let(:price_group) { product.price_policies.first.price_group }
  let(:estimate) { create(:estimate, facility:, price_group:) }
  let(:estimate_pdf) { EstimatePdfFactory.build(estimate) }
  let(:pdf_content) { estimate_pdf.render }

  before do
    create(:estimate_detail, estimate:, product:)
  end

  it "renders pdf correctly" do
    expect(pdf_content).to be_present
    expect(pdf_content).to match(/\A%PDF-1.\d+\b/)
  end
end
