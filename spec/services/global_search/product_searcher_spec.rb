# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::ProductSearcher do
  # This spec should be database-agnostic
  before { allow(FullTextSearch::Model).to receive(:full_text_searcher).and_return(FullTextSearch::LikeSearcher) }

  subject(:results) { searcher.results }

  let(:facility) { nil }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { create(:user) }
  let!(:item) { create(:setup_item, name: "Capitalized Item") }

  describe "#results" do
    context "when the query is nil" do
      let(:query) { nil }
      it { is_expected.to be_empty }
    end

    context "when the query is whitespace only" do
      let(:query) { "   " }
      it { is_expected.to be_empty }
    end

    context "when the query matches no products" do
      let(:query) { "gobbledy gook" }
      it { is_expected.to be_empty }
    end

    context "when the query case does not match the db case" do
      let(:query) { "item" }
      it { is_expected.to contain_exactly(item) }
    end

    context "when the query matches results the user doesn't have permissions to view" do
      let(:query) { "item" }

      before do
        item.update_attributes(is_hidden: true)
      end

      it { is_expected.to be_empty }
    end

    context "when query matches a hidden product that the user has permissions to view" do
      let(:user) { create(:user, :staff, facility: item.facility) }
      let(:query) { "item" }

      before do
        item.update_attributes(is_hidden: true)
      end

      it { is_expected.to contain_exactly(item) }
    end

    context "when query matches a product that belongs to an inactive facility" do
      let(:inactive_facility) { create(:facility, is_active: false) }
      let(:query) { "item" }

      before do
        item.update_attributes(facility: inactive_facility)
      end

      it { is_expected.to be_empty }
    end

  end

end
