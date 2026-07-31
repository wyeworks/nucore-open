# frozen_string_literal: true

require "rails_helper"

RSpec.describe "facilities journals" do
  describe "search" do
    let(:facility) { create(:setup_facility) }

    before { login_as create(:user, :administrator) }

    it "includes checkbox to filter suspended accounts" do
      get new_facility_journal_path(facility)

      expect(page).to have_field("search[suspended_accounts]", type: :checkbox)
    end
  end
end
