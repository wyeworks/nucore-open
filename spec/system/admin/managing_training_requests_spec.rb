# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing training a request", feature_setting: { training_requests: true, reload_routes: true } do
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:training_request) { create(:training_request) }
  let(:facility) { training_request.product.facility }
  let(:instrument) { training_request.product }
  let(:user) { training_request.user }

  before { login_as director }

  it "can remove a training request" do
    visit facility_training_requests_path(facility)

    expect(page).to have_content(user.email)

    click_button "Remove"

    expect(page).not_to have_content(user.email)
    expect(page).to have_content("There are no outstanding training requests.")
  end

  it "can add a note and see who wrote it" do
    visit facility_training_requests_path(facility)

    fill_in "training_request_note", with: "Emailed them about next week's session"
    click_button "Save"

    expect(page).to have_content("The note for #{user} / #{instrument} has been saved.")
    expect(page).to have_field("training_request_note", with: "Emailed them about next week's session")
    expect(page).to have_content(director.to_s)
    expect(training_request.reload.note_updated_by).to eq(director)
  end

  describe "as facility staff" do
    let(:staff) { create(:user, :staff, facility:) }

    before do
      training_request.update_note("Already reached out", director)
      login_as staff
    end

    it "sees the note but cannot edit it" do
      visit facility_training_requests_path(facility)

      expect(page).to have_content("Already reached out")
      expect(page).to have_content(director.to_s)
      expect(page).not_to have_field("training_request_note")
      expect(page).not_to have_button("Save")
    end
  end
end
