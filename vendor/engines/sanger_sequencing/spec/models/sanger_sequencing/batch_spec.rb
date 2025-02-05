# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Batch do
  describe ".for_product_group" do
    subject { described_class.for_product_group(group) }

    let!(:blank_batch) { create(:sanger_sequencing_batch, group: "") }
    let!(:nil_batch) { create(:sanger_sequencing_batch, group: nil) }
    let!(:default_group_batch) { create(:sanger_sequencing_batch, group: "default") }
    let!(:fragment_group_batch) { create(:sanger_sequencing_batch, group: "fragment") }

    before { create(:product_group, :fragment) }

    context "with group given as nil" do
      let(:group) { nil }
      it { is_expected.to match_array [blank_batch, nil_batch, default_group_batch] }
    end

    context "with group given as empty string" do
      let(:group) { "" }
      it { is_expected.to match_array [blank_batch, nil_batch, default_group_batch] }
    end

    context "with a group provided" do
      let(:group) { "fragment" }
      it { is_expected.to match_array [fragment_group_batch] }
    end
  end
end
