require "rails_helper"

RSpec.describe SangerSequencing::Batch do
  describe ".for_product_group" do
    subject { described_class.for_product_group(group) }

    before { FactoryGirl.create(:product_group, :fragment) }
    let!(:blank_batch) { FactoryGirl.create(:sanger_sequencing_batch, group: "") }
    let!(:nil_batch) { FactoryGirl.create(:sanger_sequencing_batch, group: nil) }
    let!(:grouped_batch) { FactoryGirl.create(:sanger_sequencing_batch, group: "fragment") }

    context "with group given as nil" do
      let(:group) { nil }
      it { is_expected.to match_array [blank_batch, nil_batch] }
    end

    context "with group given as empty string" do
      let(:group) { "" }
      it { is_expected.to match_array [blank_batch, nil_batch] }
    end

    context "with a group provided" do
      let(:group) { "fragment" }
      it { is_expected.to match_array [grouped_batch] }
    end
  end
end
