# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a service" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:director) { FactoryBot.create(:user, :facility_director, facility:) }
  let(:administrator) { create(:user, :administrator) }
  let(:logged_in_user) { director }
  before { login_as logged_in_user }

  it "can create and edit a service" do
    visit facility_products_path(facility)
    click_link "Services (0)", exact: true
    click_link "Add Service"

    fill_in "Name", with: "My New Service", match: :first
    fill_in "URL Name", with: "new-service"
    click_button "Create"

    expect(current_path).to eq(manage_facility_service_path(facility, Service.last))
    expect(page).to have_content("My New Service")

    click_link "Edit"
    fill_in "service[description]", with: "Some description"
    click_button "Save"

    expect(current_path).to eq(manage_facility_service_path(facility, Service.last))
    expect(page).to have_content("Some description")
  end

  it "can add order forms" do
    visit facility_products_path(facility)
    click_link "Services (0)", exact: true
    click_link "Add Service"

    fill_in "Name", with: "My New Service", match: :first
    fill_in "URL Name", with: "new-service"
    click_button "Create"

    expect(current_path).to eq(manage_facility_service_path(facility, Service.last))
    expect(page).to have_content("My New Service")

    click_link "Order Forms"
    fill_in "Service URL", with: "http://example.com"
    click_button "Add"

    expect(page).to have_content("http://example.com")
    expect(page).to have_content("Online Order Form added")

    attach_file("File", "#{Rails.root}/spec/files/template1.txt")
    click_button "Upload"

    expect(page).to have_content("Date Uploaded")
    expect(page).not_to have_content("No Downloadable Order Forms have been uploaded")
  end

  context "when billing mode is Nonbillable" do
    include_examples "creates a product with billing mode", "service", "Nonbillable"
  end

  context "when billing mode is Skip Review" do
    include_examples "creates a product with billing mode", "service", "Skip Review"
  end
end
