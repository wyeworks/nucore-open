# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::OrderSearcher do
  subject(:results) { searcher.results }

  let(:facility) { nil }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { nil }

  describe "#results" do
    context "when the query matches no orders" do
      let(:query) { "gobbledy gook" }
      it { is_expected.to be_empty }
    end

    context "when the query is nil" do
      let(:query) { nil }
      it { is_expected.to be_empty }
    end

    context "when the query contains only whitespace" do
      let(:query) { " " }
      it { is_expected.to be_empty }
    end

    context "when the query has a lowercased prefix" do
      let(:query) { "cx-36" }

      it "searches externally" do
        expect(searcher)
          .to receive(:search_external)
          .with(query)
          .and_call_original
        expect(searcher).to receive(:insensitive_where)

        searcher.results
      end
    end
  end
end
