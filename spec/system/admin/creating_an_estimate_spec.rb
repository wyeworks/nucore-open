# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Creating an estimate", :js
) do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }
  let!(:user) { create(:user) }
  let(:price_group) { facility.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) { create(:item_price_policy, product: item, price_group:) }
  let!(:instrument) { create(:setup_instrument, facility:) }
  let!(:instrument_price_policy) { create(:instrument_price_policy, product: instrument, price_group:) }
  let!(:bundle) { create(:bundle, facility:, bundle_products: [item, instrument]) }
  let(:other_facility) { create(:setup_facility) }
  let!(:other_item) { create(:setup_item, facility: other_facility, cross_core_ordering_available: true) }
  let!(:other_item_price_policy) { create(:item_price_policy, product: other_item, price_group: price_group) }
  let!(:item_without_price_policy) { create(:setup_item, facility:) }

  before { login_as director }

  it "can create an estimate" do
    visit facility_estimates_path(facility)

    expect(page).to have_selector("#admin_estimates_tab")
    expect(page).to have_content facility.to_s

    click_link "Add Estimate"
    expect(page).to have_content "Create an Estimate"

    fill_in "Name", with: "Test Estimate"
    fill_in "Expires at", with: 1.month.from_now.strftime("%m/%d/%Y")
    select_from_chosen price_group.name, from: "Price group"

    fill_in "Note", with: "This is a test estimate"

    expect(page).to have_content("No results found")

    select_user("#estimate_user_id_chosen", user)

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

    select_from_chosen other_facility.name, from: Facility.model_name.human, scroll_to: :center
    select_from_chosen other_item.name, from: "Product"
    click_button "Add Product to Estimate"

    wait_for_ajax

    within '#new_estimate_estimate_details' do
      other_item_row = all('tr').last
      columns = other_item_row.all('td')
      first_column_text = columns[0].text
      expect(first_column_text).to eq "#{other_item.name} (#{other_facility.name})"
    end

    expect(page).to have_content("Remove", count: 3)

    select_from_chosen facility.name, from: Facility.model_name.human, scroll_to: :center
    select_from_chosen item_without_price_policy.name, from: "Product"
    click_button "Add Product to Estimate"

    wait_for_ajax

    within '#new_estimate_estimate_details' do
      item_without_price_policy_row = all('tr').last
      columns = item_without_price_policy_row.all('td')
      first_column_text = columns[0].text
      expect(first_column_text).to have_content(item_without_price_policy.name)
    end

    click_button "Add Estimate"

    expect(page).not_to have_content "Estimate successfully created"

    within '#new_estimate_estimate_details' do
      item_without_price_policy_row = all('tr').last
      columns = item_without_price_policy_row.all('td')
      first_column_text = columns[0].text
      expect(first_column_text).to have_content(item_without_price_policy.name)
      expect(first_column_text).to have_content("No price policy found.")

      remove_button = columns[3].find('.remove-estimate-detail')
      remove_button.click
    end

    select_user("#estimate_user_id_chosen", user)

    click_button "Add Estimate"

    expect(page).to have_content "Estimate successfully created"

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
    expect(page).to have_content "#{other_item.name} (#{other_facility.name})"
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(other_item_price_policy.unit_cost) # 1 item
    total = other_item_price_policy.unit_cost +
            (item_price_policy.unit_cost * 2) +
            (instrument_price_policy.usage_rate * 180)
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(total)
  end
end
