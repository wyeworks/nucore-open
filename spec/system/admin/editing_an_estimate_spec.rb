# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Editing an estimate", :js,
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
  let(:other_facility) { create(:setup_facility) }
  let!(:other_item) { create(:setup_item, facility: other_facility, cross_core_ordering_available: true) }
  let!(:other_item_price_policy) { create(:item_price_policy, product: other_item, price_group: price_group) }
  
  let!(:estimate) do
    est = create(:estimate, 
                facility:, 
                user: user, 
                created_by_user: director, 
                name: "Original Estimate", 
                note: "Original note",
                expires_at: 1.month.from_now)
    
    create(:estimate_detail, estimate: est, product: item, quantity: 1, price_policy: item_price_policy)
    est
  end

  before { login_as director }

  it "can edit an estimate" do
    visit facility_estimate_path(facility, estimate)

    expect(page).to have_content "Estimate ##{estimate.id} - Original Estimate"
    
    click_link "Edit"
    expect(page).to have_content "Edit Estimate"

    fill_in "Name", with: "Updated Estimate Title"
    fill_in "Note", with: "Updated note text"
    fill_in "Expires at", with: 2.months.from_now.strftime("%m/%d/%Y")

    within '#new_estimate_estimate_details' do
      input_field = all('tr').first.all('td')[1].find('input')
      input_field.fill_in with: "3"
    end

    select_from_chosen instrument.name, from: "Product"
    click_button "Add Product to Estimate"
    
    wait_for_ajax
    
    within '#new_estimate_estimate_details' do
      instrument_row = all('tr').last
      columns = instrument_row.all('td')
      
      quantity_field = columns[1].find('input')
      quantity_field.fill_in with: "1"
      
      duration_field = columns[2].find('input')
      duration_field.fill_in with: "2:30"
    end
    
    select_from_chosen other_facility.name, from: Facility.model_name.human, scroll_to: :center
    select_from_chosen other_item.name, from: "Product"
    click_button "Add Product to Estimate"
    
    wait_for_ajax
    
    within '#new_estimate_estimate_details' do
      other_item_row = all('tr').last
      columns = other_item_row.all('td')
      expect(columns[0].text).to eq "#{other_item.name} (#{other_facility.name})"
    end
    
    within '#new_estimate_estimate_details' do
      first_row = all('tr').first
      columns = first_row.all('td')
      remove_button = columns[3].find('.remove-estimate-detail')
      remove_button.click
    end
    
    click_button "Update"
    
    expect(page).to have_content "Estimate was successfully updated"
    expect(page).to have_content "Estimate ##{estimate.id} - Updated Estimate Title"
    expect(page).to have_content "Updated note text"
    expect(page).to have_content 2.months.from_now.strftime("%m/%d/%Y")
    
    expect(page).not_to have_content item.name
    expect(page).to have_content instrument.name
    expect(page).to have_content "#{other_item.name} (#{other_facility.name})"
    
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(instrument_price_policy.usage_rate * 150)
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(other_item_price_policy.unit_cost)
    
    total = (instrument_price_policy.usage_rate * 150) + other_item_price_policy.unit_cost
    expect(page).to have_content ActionController::Base.helpers.number_to_currency(total)
  end
end