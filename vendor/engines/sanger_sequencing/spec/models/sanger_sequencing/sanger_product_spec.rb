# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::SangerProduct do
  let(:product) { create(:setup_service) }

  describe "#create_default_primers" do
    let(:sanger_product) { described_class.create(product:) }
    let(:subject) { sanger_product.create_default_primers }

    it "creates primers" do
      expect { subject }.to(
        change { sanger_product.reload.primers.count }.from(0)
      )
    end

    it "takes primers from the default list" do
      subject

      expect(
        sanger_product.primers.pluck(:name)
      ).to eq(
        SangerSequencing::Primer.default_list
      )
    end
  end
end
