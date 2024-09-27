require "rails_helper"

RSpec.describe "Instrument Schedule Display Order" do
  let(:facility) { create(:setup_facility) }
  let!(:instrument) { create(:instrument, name: "First", facility: facility) }
  let!(:instrument2) { create(:instrument, name: "Second", facility: facility) }
  let!(:instrument3) { create(:instrument, name: "Third", facility: facility, schedule: instrument2.schedule, is_hidden: true) }
  let!(:instrument_z) { create(:instrument, name: "ZZZ New Instrument (no position)", facility: facility) }
  let!(:instrument_a) { create(:instrument, name: "AAA New Instrument (no position)", facility: facility) }
  let!(:instrument_c) { create(:instrument, name: "CCC New Instrument (no position)", facility: facility) }

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
    let(:user) { create(:user, :facility_director, facility: facility) }

    # Some of these specs have been failing even though the arrays look the same in the error message.
    # I wasn't able to reproduce the failure locally.
    it "can reorder the schedules", :js do
      # check starting display order
      visit dashboard_facility_instruments_path(facility)
      expect(["First", "Second", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit timeline_facility_reservations_path(facility)
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

      wait_for_ajax

      expect(["Second", "Third", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      # check the new display order
      visit timeline_facility_reservations_path(facility)
      expect(["Second", "Third", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit facility_public_timeline_path(facility)
      expect(["Second", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order

      visit dashboard_facility_instruments_path(facility)
      expect(["Second", "First", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order
    end
  end

  describe "as facility staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it "can view the show page, but not edit the display order" do
      visit facility_instrument_schedule_position_path(facility)
      click_link "Instrument Display Order"
      expect(["First", "Shared schedule: Second Schedule", "AAA New", "CCC New", "ZZZ New"]).to appear_in_order
      expect(page).not_to have_link("Edit")
    end

    it "can't directly access the edit page" do
      visit edit_facility_instrument_schedule_position_path(facility)
      expect(page.status_code).to eq(403)
    end
  end

end
