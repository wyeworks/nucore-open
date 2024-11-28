# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::GlobalSearch::JournalSearcher do
  let!(:facility) { nil }
  let(:facility_a) { FactoryBot.create(:facility) }
  let(:facility_b) { FactoryBot.create(:facility) }
  let!(:facility_a_journals) do
    [
      create(:journal, facility: facility_a, created_by: user.id, reference: "ALS001", journal_date: 2.days.ago.change(usec: 0)),
      create(:journal, facility: facility_a, created_by: user.id, reference: "ALS002", journal_date: 2.days.ago.change(usec: 0)),
    ]
  end
  let!(:facility_b_journals) do
    [
      create(:journal, facility: facility_b, created_by: user.id, reference: "ALS003", journal_date: 2.days.ago.change(usec: 0)),
      create(:journal, facility: facility_b, created_by: user.id, reference: "ALS004", journal_date: 2.days.ago.change(usec: 0)),
    ]
  end
  let(:query) { nil }
  let(:searcher) { described_class.new(user, facility, query) }
  let(:user) { FactoryBot.create(:user, :administrator) }

  describe "#results" do
    subject(:results) { searcher.results }

    shared_examples_for "it returns empty results for empty queries" do
      context "when the query is nil" do
        it { is_expected.to be_empty }
      end

      context "when the query is an empty string" do
        let(:query) { "" }
        it { is_expected.to be_empty }
      end

      context "when the query contains only whitespace" do
        let(:query) { " \t \r \n " }
        it { is_expected.to be_empty }
      end

      context "when the query does not match a journal reference" do
        let(:query) { "not a reference" }
        it { is_expected.to be_empty }
      end

      context "when the query does not match an ALS number" do
        let(:query) { "not a number" }
        it { is_expected.to be_empty }
      end
    end

    context "when in a facility context" do
      let(:facility) { facility_a }

      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a journal reference" do
        context "that belongs to the facility" do
          let(:journal_a) { facility_a_journals.first }

          context "and the case matches" do
            let(:query) { journal_a.reference }
            it { is_expected.to eq [journal_a] }
          end

          context "and the case does not match" do
            let(:query) { journal_a.reference.upcase }
            it { is_expected.to eq [journal_a] }
          end

          context "and the reference partially matches the query" do
            before { journal_a.update_attribute(:reference, "Some reference") }
            let(:query) { "ME ref" }
            it { is_expected.to eq [journal_a] }
          end
        end

        context "that belongs to another facility" do
          let(:query) { facility_b_journals.first.reference }
          it { is_expected.to be_empty }
        end
      end

      context "when the query matches a ALS number" do
        context "that belongs to the facility" do
          let(:journal_a) { facility_a_journals.first }

          context "and matches" do
            let(:query) { journal_a.als_number }
            it { is_expected.to eq [journal_a] }
          end
        end

        context "that belongs to another facility" do
          let(:query) { facility_b_journals.first.reference }
          it { is_expected.to be_empty }
        end
      end

      context "when journals in different facilities have identical references" do
        let(:journal_a) { facility_a_journals.first }
        let(:journal_b) { facility_b_journals.first }

        before(:each) do
          journal_b.update_attribute(:reference, journal_a.reference)
          expect(journal_a.reference).to eq(journal_b.reference)
        end

        context "when the query matches this repeated journal reference" do
          let(:query) { journal_b.reference }

          it "returns the journal belonging to this facility only" do
            is_expected.to match_array [journal_a]
          end
        end
      end

      context "when journals in different facilities have similar references" do
        let(:journal_a) { facility_a_journals.first }
        let(:journal_b) { facility_b_journals.first }

        before(:each) do
          journal_a.update_attribute(:reference, "Some Label A")
          journal_a.update_attribute(:reference, "Some Label B")
        end

        context "when the query partially matches both journal references" do
          let(:query) { "ME lab" }

          it "returns the journal belonging to this facility only" do
            is_expected.to match_array [journal_a]
          end
        end
      end
    end

    shared_examples_for "it's not in a single facility context" do
      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a journal reference" do
        let(:query) { facility_b_journals.last.reference }
        it { is_expected.to eq [facility_b_journals.last] }
      end

      context "when journals in different facilities have identical references" do
        let(:journal_a) { facility_a_journals.first }
        let(:journal_b) { facility_b_journals.first }

        before(:each) do
          journal_b.update_attribute(:reference, journal_a.reference)
          expect(journal_a.reference).to eq(journal_b.reference)
        end

        context "when the query matches this repeated journal reference" do
          let(:query) { journal_a.reference }

          it "returns journals from both facilities" do
            is_expected.to match_array [journal_a, journal_b]
          end
        end
      end

      context "when journals in different facilities have similar references" do
        let(:journal_a) { facility_a_journals.first }
        let(:journal_b) { facility_b_journals.first }

        before(:each) do
          journal_a.update_attribute(:reference, "Some journalA Label")
          journal_b.update_attribute(:reference, "Some journalB Label")
        end

        context "when the query partially matches both journal references" do
          let(:query) { "ME jourNAL" }

          it "returns both journals" do
            is_expected.to match_array [journal_a, journal_b]
          end
        end
      end
    end

    context "when in a global context" do
      it_behaves_like "it's not in a single facility context"
    end

    context "when in a cross-facility (ALL) context" do
      let(:facility) { Facility.cross_facility }

      it_behaves_like "it's not in a single facility context"
    end
  end

  describe "#template" do
    it { expect(searcher.template).to eq("journals") }
  end
end
