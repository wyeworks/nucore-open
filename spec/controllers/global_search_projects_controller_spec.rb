# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearchController do
  describe ".searcher_classes" do
    it "includes the project searcher" do
      expect(described_class.searcher_classes)
        .to include(GlobalSearch::ProjectSearcher)
    end
  end

  describe "a facility staff" do
    let(:facility) { project.facility }
    let(:project) { create(:project) }
    let(:user) { create(:user, :staff, facility:) }
    let(:results) { assigns[:searchers].find { |s| s.template == "projects" }.results }
    before { sign_in user }

    context "while not in the facility" do
      it "finds the project" do
        get :index, params: { search: project.name }
        expect(results).to include(project)
      end
    end

    context "while in another facility" do
      let(:facility2) { create(:facility) }
      it "does not find the project" do
        get :index, params: { facility_id: facility2, search: project.name }
        expect(results).not_to include(project)
      end
    end

    context "while in the facility" do
      it "finds the project" do
        get :index, params: { facility:, search: project.name }
        expect(results).to include(project)
      end
    end
  end
end
