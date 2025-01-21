# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Submission do
  describe "create" do
    let(:order_detail) { build(:order_detail) }
    let(:subject) { described_class.create!(order_detail:) }

    it "can be created" do
      expect(subject.order_detail).to eq(order_detail)
    end

    describe "#create_prefilled_sample" do
      it "returns a sample" do
        expect(subject.create_prefilled_sample).to be_kind_of(SangerSequencing::Sample)
      end

      it "sets customer_sample_id to the id of the sample padded and limitedto 4 places" do
        sample = subject.create_prefilled_sample
        expect(sample.customer_sample_id).to eq(("%04d" % sample.id).last(4))
      end
    end
  end

  describe "#for_product_group" do
    let(:facility) { create(:setup_facility) }
    let(:user) { create(:user) }
    let(:order) { create(:order, created_by: user.id, user:, state: :purchased) }

    def has_group(group)
      proc do |submission|
        submission.order_detail.product.sanger_product&.group == group
      end
    end

    before do
      [nil, "default", "fragment"].each do |group|
        product = create(:service, facility:)
        product.create_sanger_product(group:) if group.present?
        order_detail = create(:order_detail, product:, order:)
        described_class.create(order_detail:)
      end
    end

    context "when it's nil" do
      it "returns submissions for nil and default groups" do
        submissions = described_class.purchased.for_product_group(nil)

        expect(submissions.count(&has_group(nil))).to eq 1
        expect(submissions.count(&has_group("default"))).to eq 1
      end
    end

    context "when default" do
      it "returns submissions for nil and default groups" do
        submissions_nil = described_class.purchased.for_product_group(nil)
        submissions_default = described_class.purchased.for_product_group("default")

        expect(submissions_nil.to_a).to eq(submissions_default.to_a)
      end
    end

    context "when fragment" do
      it "returns submissions for products in fragment group" do
        submissions = described_class.purchased.for_product_group("fragment")

        expect(submissions.count).to eq 1
        expect(submissions.count(&has_group("fragment"))).to eq 1
      end
    end
  end
end
