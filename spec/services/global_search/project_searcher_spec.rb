# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::ProjectSearcher do
  let(:facility) { nil }
  let!(:facility_a) { FactoryBot.create(:facility) }
  let!(:facility_b) { FactoryBot.create(:facility) }
  let!(:facility_a_projects) { FactoryBot.create_list(:project, 2, facility: facility_a) }
  let!(:facility_b_projects) { FactoryBot.create_list(:project, 2, facility: facility_b) }
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

      context "when the query does not match a project name" do
        let(:query) { "not a project" }
        it { is_expected.to be_empty }
      end
    end

    context "when in a facility context" do
      let(:facility) { facility_a }

      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a project name" do
        context "that belongs to the facility" do
          let(:project_a) { facility_a_projects.first }

          context "and the case matches" do
            let(:query) { project_a.name }
            it { is_expected.to eq [project_a] }
          end

          context "and the case does not match" do
            let(:query) { project_a.name.upcase }
            it { is_expected.to eq [project_a] }
          end

          context "and the name partially matches the query" do
            before { project_a.update_attribute(:name, "Some Label") }
            let(:query) { "ME lab" }
            it { is_expected.to eq [project_a] }
          end
        end

        context "that belongs to another facility" do
          let(:query) { facility_b_projects.first.name }
          it { is_expected.to be_empty }
        end
      end

      context "when the query matches a project id" do
        context "that belongs to the facility" do
          let(:project_a) { facility_a_projects.first }
          let(:query) { project_a.id.to_s }
          it { is_expected.to eq [project_a] }
        end
      end

      context "when projects in different facilities have identical names" do
        let(:project_a) { facility_a_projects.first }
        let(:project_b) { facility_b_projects.first }

        before(:each) do
          project_b.update_attribute(:name, project_a.name)
          expect(project_a.name).to eq(project_b.name)
        end

        context "when the query matches this repeated project name" do
          let(:query) { project_b.name }

          it "returns the project belonging to this facility only" do
            is_expected.to match_array [project_a]
          end
        end
      end

      context "when projects in different facilities have similar names" do
        let(:project_a) { facility_a_projects.first }
        let(:project_b) { facility_b_projects.first }

        before(:each) do
          project_a.update_attribute(:name, "Some Label A")
          project_a.update_attribute(:name, "Some Label B")
        end

        context "when the query partially matches both project names" do
          let(:query) { "ME lab" }

          it "returns the project belonging to this facility only" do
            is_expected.to match_array [project_a]
          end
        end
      end
    end

    shared_examples_for "it's not in a single facility context" do
      it_behaves_like "it returns empty results for empty queries"

      context "when the query matches a project name" do
        let(:query) { facility_b_projects.last.name }
        it { is_expected.to eq [facility_b_projects.last] }
      end

      context "when projects in different facilities have identical names" do
        let(:project_a) { facility_a_projects.first }
        let(:project_b) { facility_b_projects.first }

        before(:each) do
          project_b.update_attribute(:name, project_a.name)
          expect(project_a.name).to eq(project_b.name)
        end

        context "when the query matches this repeated project name" do
          let(:query) { project_a.name }

          it "returns projects from both facilities" do
            is_expected.to match_array [project_a, project_b]
          end
        end
      end

      context "when projects in different facilities have similar names" do
        let(:project_a) { facility_a_projects.first }
        let(:project_b) { facility_b_projects.first }

        before(:each) do
          project_a.update_attribute(:name, "Some ProjectA Label")
          project_b.update_attribute(:name, "Some ProjectB Label")
        end

        context "when the query partially matches both project names" do
          let(:query) { "ME proJEC" }

          it "returns both projects" do
            is_expected.to match_array [project_a, project_b]
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
    it { expect(searcher.template).to eq("projects") }
  end
end
