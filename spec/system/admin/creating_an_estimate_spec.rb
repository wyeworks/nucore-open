# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Creating an estimate", :js,
  feature_setting: { user_based_price_groups: true },
) do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let(:price_group) { user.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group:) }
  let!(:instrument) { create(:setup_instrument, facility:) }
  let!(:instrument_price_policy) { create(:instrument_price_policy, product: instrument, price_group:) }
  let!(:bundle) { create(:bundle, facility:, bundle_products: [item, instrument]) }

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
    select_from_chosen bundle.name, from: "Product"
    click_button "Add Product to Estimate"

    wait_for_ajax

    within '#new_estimate_estimate_details' do
      all('tr').each do |row|
        columns = row.all('td')
        first_column_text = columns[0].text
        product = bundle.products.find { |p| p.name == first_column_text }

        # Quantity
        second_column_field = columns[1].find('input')
        second_column_field.fill_in with: "2"

        if product.is_a?(Instrument)
          third_column_field = columns[2].find('input')
          third_column_field.fill_in with: "1:30"
        end
      end
    end

    expect(page).to have_content("Remove", count: 2)

    click_button "Add Estimate"

    expect(page).to have_content "Estimate successfully created"
    expect(page).to have_content "Estimate ##{Estimate.last.id} - Test Estimate"
    expect(page).to have_content "This is a test estimate"
    expect(page).to have_content 1.month.from_now.strftime("%m/%d/%Y")
    expect(page).to have_content director.full_name
    expect(page).to have_content user.full_name
    expect(page).to have_content item.name
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(item_price_policy.unit_cost * 2) # 2 items
    expect(page).to have_content instrument.name
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(instrument_price_policy.usage_rate * 180) # 1.5 hours * 2 = 3 hours
  end
end
