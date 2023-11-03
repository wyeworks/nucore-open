# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secure room Scheduling Tab" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:user) { FactoryBot.create(:user, :administrator) }

  before do
    login_as user
  end

  let!(:secure_room) do
    FactoryBot.create(:setup_secure_room, facility: facility)
  end

  context "new schedule rule" do
    before do
      visit new_facility_secure_room_schedule_rule_path(facility, secure_room)
    end

    it "shows all Schedule rule fields" do
      expect(page).to have_content(secure_room.name)
      expect(page).to have_content("Add Schedule Rule")
      expect(page).to have_content("Price Group Discounts")

      check "Sun"

      select "7", from: "schedule_rule_start_hour"
      select "8", from: "schedule_rule_end_hour"

      click_button "Create"

      expect(page).to have_content("Days of Week")
      expect(page).to have_content("Start Time")
      expect(page).to have_content("End Time")
      expect(page).to have_content("Discount (%)")
    end
  end

  context "edit schedule rules" do
    before do
      visit edit_facility_secure_room_schedule_rule_path(facility, secure_room, secure_room.schedule_rules.first)
    end

    it "shows all Schedule rule fields" do
      expect(page).to have_content("Editing Schedule Rule")
      expect(page).to have_content("Price Group Discounts")
    end
  end

end
