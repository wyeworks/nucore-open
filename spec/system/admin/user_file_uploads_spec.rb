# frozen_string_literal: true

require "rails_helper"

RSpec.describe "user file uploads" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:admin) { create(:user, :facility_administrator, facility: facility) }
  let(:user) { create(:user) }
  let!(:file) { create(:stored_file, file_type: "user_info", name: "file 1", user_id: user.id, creator: admin) }

  before do
    login_as admin
    visit facility_user_user_file_uploads_path(facility, user)
  end

  it "can upload a file" do
    fill_in "Name", with: "doc 2"
    attach_file "stored_file_file", "#{Rails.root}/spec/files/template1.txt"
    click_on "Upload"
    expect(page).to have_content "Delete doc 2"
  end

  it "can delete a file" do
    expect(page).to have_content "file 1"
    click_on "Delete"
    expect(page).not_to have_content "file 1"
  end
end
