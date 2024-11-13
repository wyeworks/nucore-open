# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an item" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:director) { FactoryBot.create(:user, :facility_director, facility:) }
  let(:administrator) { create(:user, :administrator) }
  let(:logged_in_user) { director }
  before { login_as logged_in_user }

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
    expect(page).to have_content(I18n.t("views.admin.products.product_fields.hints.cross_core_ordering_available"))

    click_link "Edit"
    fill_in "item[description]", with: "Some description"
    uncheck "item[cross_core_ordering_available]"
    click_button "Save"

    expect(current_path).to eq(manage_facility_item_path(facility, Item.last))
    expect(page).to have_content("Some description")
    expect(page).to have_content("#{I18n.t('views.admin.products.product_fields.hints.cross_core_ordering_available')}\nNo")
  end

  context "when billing mode is Nonbillable" do
    include_examples "creates a product with billing mode", "service", "Nonbillable"
  end

  context "when billing mode is Skip Review" do
    include_examples "creates a product with billing mode", "service", "Skip Review"
  end
end
