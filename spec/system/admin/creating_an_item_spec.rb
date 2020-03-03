# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an item" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }
  before { login_as director }

  it "can create and edit an item" do
    visit facility_products_path(facility)
    click_link "Items"
    click_link "Add Item"

    fill_in "Name", with: "My New Item", match: :first
    fill_in "URL Name", with: "new-item"
    select "Required", from: "item[user_notes_field_mode]"
    click_button "Create"

    expect(current_path).to eq(manage_facility_item_path(facility, Item.last))
    expect(page).to have_content("My New Item")
    expect(page).to have_content("Required")

    click_link "Edit"
    fill_in "item[description]", with: "Some description"
    click_button "Save"

    expect(current_path).to eq(manage_facility_item_path(facility, Item.last))
    expect(page).to have_content("Some description")
  end
end
