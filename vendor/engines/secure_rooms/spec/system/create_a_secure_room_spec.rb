# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a SecureRoom" do
  let(:facility) { create(:setup_facility) }
  let(:admin) { create(:user, :administrator) }
  before { login_as admin }

  it "can create and edit a secure room" do
    visit facility_products_path(facility)
    click_link "Secure Rooms"
    click_link "Add Secure Room"
    fill_in "secure_room[name]", with: "New Room"
    fill_in "URL Name", with: "new-room"
    click_button "Create"

    expect(current_path).to eq(manage_facility_secure_room_path(facility, SecureRoom.last))

    visit facility_secure_rooms_path(facility)
    click_link "New Room"
    click_link "Edit"

    fill_in "secure_room[description]", with: "Some description"
    click_button "Save"

    room = SecureRoom.last
    expect(room).to be_requires_approval
    expect(room).to be_hidden
    expect(room.description).to eq("Some description")
  end

  describe "price policies", :js do
    let!(:global_price_group) { create(:price_group, :global) }
    let!(:facility_price_group) { PriceGroup.find_by(facility_id: facility.id) }
    let(:base_price_group) { PriceGroup.base }
    let(:external_price_group) { PriceGroup.external }
    let(:secure_room) { create(:secure_room, facility: facility) }

    before do
      visit manage_facility_secure_room_path(secure_room.facility, secure_room)
      click_link "Pricing"
      click_link "Add Pricing Rules"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "45"
      uncheck "price_policy_#{external_price_group.id}[can_purchase]"
      uncheck "price_policy_#{facility_price_group.id}[can_purchase]"
      fill_in "price_policy_#{global_price_group.id}[usage_subsidy]", with: "60"

      fill_in "Note", with: "This is a note"

      click_button "Add Pricing Rules"
    end

    it "sets the fields" do
      expect(page).to have_content(base_price_group.name)
      expect(page).not_to have_content(external_price_group.name)
      expect(page).to have_content("$120.00")
      expect(page).to have_content("$22.50") # minimum cost, subsidized

      expect(page).to have_content("This is a note")
    end
  end
end
