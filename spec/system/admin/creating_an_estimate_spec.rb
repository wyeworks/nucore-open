# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an estimate", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let!(:product) { create(:setup_item, facility:) }
  let!(:price_policy) { create(:item_price_policy, product:, price_group: user.price_groups.first) }

  before { login_as director }

  it "can create an estimate" do
    visit facility_estimates_path(facility)

    expect(page).to have_selector("#admin_estimates_tab")
    expect(page).to have_content facility.to_s

    click_link "Add Estimate"
    expect(page).to have_content "Create an Estimate"

    fill_in "Name", with: "Test Estimate"
    fill_in "Expires at", with: 1.month.from_now.strftime("%m/%d/%Y")

    fill_in "Note", with: "This is a test estimate"

    expect(page).to have_content("No results found")

    page.execute_script("$('#estimate_user_id_chosen').trigger('mousedown')")
    page.execute_script("$('#estimate_user_id_chosen .chosen-search input').val('#{user.first_name}').trigger('input')")

    wait_for_ajax

    # Make sure calendar is not open
    find("#estimate_user_id_chosen").click
    select_from_chosen user.full_name, from: "User"

    expect(page).to have_content "Add Products to Estimate"
    select_from_chosen product.name, from: "Product"
    click_button "Add Product to Estimate"

    expect(page).to have_content "Remove"

    click_button "Add Estimate"

    expect(page).to have_content "Estimate successfully created"
    expect(page).to have_content "Estimate ##{Estimate.last.id} - Test Estimate"
    expect(page).to have_content "This is a test estimate"
    expect(page).to have_content 1.month.from_now.strftime("%m/%d/%Y")
    expect(page).to have_content director.full_name
    expect(page).to have_content user.full_name
  end
end
