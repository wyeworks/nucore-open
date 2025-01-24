# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::SangerEnabledProduct do
  let(:service) { create :setup_service }

  it "includes the module" do
    expect(service.class).to include(described_class)
  end

  describe "#create_sanger_product_with_default_primers" do
    let(:subject) { service.create_sanger_product_with_default_primers }

    it "responds to expected method" do
      expect(service).to respond_to(:create_sanger_product_with_default_primers)
    end

    it "returns a sanger product" do
      expect(subject).to match(SangerSequencing::SangerProduct)
    end

    it "creates a sanger product" do
      expect { subject }.to(
        change do
          service.reload.sanger_product
        end.from(nil).to(SangerSequencing::SangerProduct)
      )
    end

    it "creates primers" do
      expect(service.sanger_product&.primers).to be nil

      subject

      expect(
        service.reload.sanger_product.primers.all?(
          SangerSequencing::Primer
        )
      ).to be true
    end
  end
end
