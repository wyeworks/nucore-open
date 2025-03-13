require "rails_helper"

RSpec.describe "Instrument Schedule Display Order" do
  let(:facility) { create(:setup_facility) }
  let!(:instrument) { create(:instrument, name: "First", facility:) }
  let!(:instrument2) { create(:instrument, name: "Second", facility:) }
  let!(:instrument3) { create(:instrument, name: "Third", facility:, schedule: instrument2.schedule, is_hidden: true) }
  let!(:instrument_z) { create(:instrument, name: "ZZZ New Instrument (no position)", facility:) }
  let!(:instrument_a) { create(:instrument, name: "AAA New Instrument (no position)", facility:) }
  let!(:instrument_c) { create(:instrument, name: "CCC New Instrument (no position)", facility:) }

  let!(:reservation) { create :reservation, :running, product: instrument }
  let!(:reservation2) { create :reservation, :running, product: instrument2 }
  let!(:reservation3) { create :reservation, :running, product: instrument3 }
  let!(:reservation4) { create :reservation, :running, product: instrument_z }
  let!(:reservation5) { create :reservation, :running, product: instrument_c }
  let!(:reservation6) { create :reservation, :running, product: instrument_a }

  before do
    instrument.schedule.update(position: 0)
    instrument2.schedule.update(position: 1)
    login_as user
  end

  describe "as a director" do
    let(:user) { create(:user, :facility_director, facility:) }

    # Some of these specs have been failing even though the arrays look the same in the error message.
    # I wasn't able to reproduce the failure locally.
    it "can reorder the schedules", :js do
      # check starting display order
      visit dashboard_facility_instruments_path(facility)

      expect(["First", "Second", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit timeline_facility_reservations_path(facility)
      wait_for { page.has_css?(".timeline_header") }
      expect(["First", "Second", "Third", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit facility_public_timeline_path(facility)
      expect(["First", "Second", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      # change the display order
      visit facility_instrument_schedule_position_path(facility)
      click_link "Instrument Display Order"
      click_link "Edit"
      expect(["First", "Shared schedule: Second Schedule", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order
      select "Second Schedule", from: "Instrument Schedules"

      find("[title='Move Up']").click
      click_button "Update Ordering"

      # Sometimes the first click doesn't work, so try again
      expected_flash_message = "The Instruments have been reordered"
      click_button "Update Ordering" unless page.has_content?(expected_flash_message)

      # This expectation has been failing from time to time even though the arrays look the same in the error message.
      # If this doesn't work, we should take a look at the matcher.
      expect(["Second", "Third", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      # check the new display order
      visit timeline_facility_reservations_path(facility)
      wait_for { page.has_css?(".timeline_header") }
      expect(["Second", "Third", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit facility_public_timeline_path(facility)
      expect(["Second", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit dashboard_facility_instruments_path(facility)
      expect(["Second", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order
    end
  end

  describe "as facility staff" do
    let(:user) { create(:user, :staff, facility:) }

    it "can view the show page, but not edit the display order" do
      visit facility_instrument_schedule_position_path(facility)
      click_link "Instrument Display Order"
      expect(["First", "Shared schedule: Second Schedule", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order
      expect(page).not_to have_link("Edit")
    end

    it_behaves_like "raises specified error", -> { visit edit_facility_instrument_schedule_position_path(facility) }, CanCan::AccessDenied
  end
end
