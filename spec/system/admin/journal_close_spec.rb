# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Journal close" do
  let(:facility) { create(:facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:facility_account) { create(:facility_account, facility: facility) }
  let!(:instrument) { create(:instrument, facility_account: facility_account) }
  let!(:journal) { create(:journal, facility: facility, is_successful: nil) }

  it "shows the closing time and user" do
    login_as director
    visit facility_journals_path(facility)

    select "Succeeded, no errors", from: "journal_status"
    fill_in "journal[reference]", with: "Reference string"
    click_button "Close Journal"
    visit facility_journal_path(facility, journal)

    expect(page).to have_content("Closed At\n#{SpecDateHelper.format_usa_datetime(Time.zone.now)}")
    expect(page).to have_content("Closed By\n#{director.full_name}")
  end
end
