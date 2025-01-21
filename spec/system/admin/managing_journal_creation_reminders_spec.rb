# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing JournalCreationReminder" do
  before do
    JournalCreationReminder.create(starts_at: 2.days.ago, ends_at: 2.days.from_now, message: "Don't forget to submit your journal!")
    login_as user
  end

  describe "as a normal user" do
    let(:user) { FactoryBot.create(:user) }

    it_behaves_like "raises specified error", -> { visit journal_creation_reminders_path }, CanCan::AccessDenied
  end

  describe "as a global admin" do
    let(:user) { FactoryBot.create(:user, :administrator) }

    it "allows creating a new reminder" do
      visit journal_creation_reminders_path
      click_link "Add New Reminder"
      fill_in "Ending Date", with: 2.days.from_now

      # Leave the message field blank to test error handling
      click_button "Submit"
      expect(page).to have_content("may not be blank")

      # Happy path
      fill_in "Message", with: "This is a FY closing window reminder"
      click_button "Submit"
      expect(page).to have_content("Reminder successfully added")
      expect(page).to have_content("This is a FY closing window reminder")
      expect(page.current_path).to eq journal_creation_reminders_path
    end

    it "editing a reminder" do
      visit journal_creation_reminders_path
      click_link "Edit"

      # Submit an invalid date to test error handling
      fill_in "Ending Date", with: 2.weeks.ago
      click_button "Submit"
      expect(page).to have_content("must be after Ending Date")

      # Happy path
      fill_in "Ending Date", with: 1.year.from_now
      click_button "Submit"
      expect(page).to have_content("Reminder successfully updated")
      expect(page).to have_content("FY#{1.year.from_now.to_s[2,2]}")
      expect(page.current_path).to eq journal_creation_reminders_path
    end

    it "deleting a reminder" do
      visit journal_creation_reminders_path
      click_link "Edit"
      click_link "Delete"

      expect(page).to have_content("Reminder successfully deleted")
      expect(page).not_to have_content("Don't forget to submit your journal!")
      expect(page.current_path).to eq journal_creation_reminders_path
    end
  end
end
