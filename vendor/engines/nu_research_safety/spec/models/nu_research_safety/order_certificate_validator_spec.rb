# frozen_string_literal: true

require "rails_helper"

RSpec.describe NuResearchSafety::OrderCertificateValidator do
  let(:product_one) { FactoryBot.create(:setup_item) }
  let(:certificate_a) { FactoryBot.create(:product_certification_requirement, product: product_one).certificate }
  let(:user) { FactoryBot.create(:user) }
  let(:order_by_user) { FactoryBot.create(:order, user: user, created_by: created_by.id) }
  let(:created_by) { user }
  let!(:order_detail_one) { FactoryBot.create(:order_detail, order: order_by_user, product: product_one) }

  let(:product_two) { FactoryBot.create(:setup_item) }
  let(:certificate_b) { FactoryBot.create(:product_certification_requirement, product: product_two).certificate }
  let!(:certification_req_p2_cA) { FactoryBot.create(:product_certification_requirement, nu_safety_certificate: certificate_a, product: product_two) }
  let!(:order_detail_two) { FactoryBot.create(:order_detail, order: order_by_user, product: product_two) }

  describe "#valid?" do
    subject(:validator) { described_class.new([order_detail_one, order_detail_two]) }

    context "with one invalid product" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_a).and_return(true)
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_b).and_return(false)
      end

      it { is_expected.not_to be_valid }
    end

    context "with both products valid" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_a).and_return(true)
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_b).and_return(true)
      end

      it { is_expected.to be_valid }
    end

    context "when ordered on behalf of" do
      let(:created_by) { FactoryBot.create(:user) }

      context "with one invalid product" do
        before do
          expect(NuResearchSafety::CertificationLookup).not_to receive(:certified?)
        end

        it { is_expected.to be_valid }
      end
    end
  end

  describe "errors" do
    subject(:validator) { described_class.new([order_detail_one, order_detail_two]) }

    context "with one invalid product" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_a).and_return(true)
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_b).and_return(false)
      end

      it "has the correct missing certs" do
        expect(validator.valid?).to be_falsey
        expect(validator.all_missing_certificates).to contain_exactly(certificate_b)
      end

      it "sets the error on the order detail" do
        expect(validator.valid?).to be_falsey
        expect(order_detail_one.errors).to be_empty
        expect(order_detail_two.errors[:base]).to include(a_string_starting_with("Missing Certificates: #{certificate_b.name}"))
      end
    end

    context "with both products valid" do
      before do
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_a).and_return(true)
        expect(NuResearchSafety::CertificationLookup).to receive(:certified?).with(user, certificate_b).and_return(true)
      end

      it "returns nothing" do
        expect(validator).to be_valid
        expect(validator.all_missing_certificates).to be_blank
      end
    end
  end
end
