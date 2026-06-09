# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing CardReaders" do
  let(:facility) { create(:setup_facility) }
  let(:secure_room) { create(:secure_room, facility: facility) }
  let(:facility_staff) { create(:user, :senior_staff, facility: facility) }
  before { login_as facility_staff }

  it "can create a card reader" do
    visit facility_secure_room_card_readers_path(facility, secure_room)
    click_link "Add Card Reader"
    fill_in "Description", with: "New Reader Description"
    fill_in "Card Reader Number", with: "New Reader Number"
    fill_in "MAC Address", with: "00:00:00:00:00:00"
    click_button "Create Card Reader"

    expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
    within(".secure_rooms_card_reader") do
      expect(page).to have_content("New Reader Description")
      expect(page).to have_content("New Reader Number")
      expect(page).to have_content("00:00:00:00:00:00")
      expect(page).to have_content("In")
    end
  end

  context "with existing card reader" do
    let!(:card_reader) { create(:card_reader, secure_room: secure_room) }

    it "can edit a card reader" do
      visit facility_secure_room_card_readers_path(facility, secure_room)
      within(".product_list") { click_link "Edit" }
      fill_in "Description", with: "Edited Reader Description"
      fill_in "Card Reader Number", with: "Edited Reader Number"
      fill_in "MAC Address", with: "FF:FF:FF:FF:FF:FF"
      select "Out", from: "Direction"
      click_button "Update Card Reader"

      expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
      within(".secure_rooms_card_reader") do
        expect(page).to have_content("Edited Reader Description")
        expect(page).to have_content("Edited Reader Number")
        expect(page).to have_content("FF:FF:FF:FF:FF:FF")
        expect(page).to have_content("Out")
      end
    end

    it "can remove a card reader" do
      visit facility_secure_room_card_readers_path(facility, secure_room)
      within(".product_list") { click_link "Remove" }

      expect(current_path).to eq(facility_secure_room_card_readers_path(facility, secure_room))
      expect { SecureRooms::CardReader.find(card_reader.id) }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "with granular permissions", feature_setting: { granular_permissions: true } do
    let!(:card_reader) { create(:card_reader, secure_room: secure_room) }
    let(:user) { create(:user) }

    before { login_as user }

    context "with read access only" do
      before { create(:facility_user_permission, user:, facility:, read_access: true) }

      it "views card readers without management links" do
        visit facility_secure_room_card_readers_path(facility, secure_room)

        within(".product_list") { expect(page).to have_content(card_reader.card_reader_number) }
        expect(page).not_to have_link("Add Card Reader")
        within(".product_list") do
          expect(page).not_to have_link("Edit")
          expect(page).not_to have_link("Remove")
        end
      end
    end

    context "with product management" do
      before { create(:facility_user_permission, user:, facility:, read_access: true, product_edition: true) }

      it "shows the management links" do
        visit facility_secure_room_card_readers_path(facility, secure_room)

        expect(page).to have_link("Add Card Reader")
        within(".product_list") do
          expect(page).to have_link("Edit")
          expect(page).to have_link("Remove")
        end
      end
    end
  end
end
