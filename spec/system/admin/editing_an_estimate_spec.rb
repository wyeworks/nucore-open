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
  let!(:other_item) { create(:setup_item, facility:) }
  let!(:other_item_price_policy) { create(:item_price_policy, product: other_item, price_group: price_group) }
  let!(:instrument) { create(:setup_instrument, facility:) }
  let!(:instrument_price_policy) { create(:instrument_price_policy, product: instrument, price_group:) }

  let!(:estimate) do
    est = create(:estimate,
                 facility:,
                 user: user,
                 created_by_user: director,
                 name: "Original Estimate",
                 note: "Original note",
                 expires_at: 1.month.from_now)

    create(:estimate_detail, estimate: est, product: item, quantity: 1, price_policy: item_price_policy)
    create(:estimate_detail, estimate: est, product: instrument, quantity: 1, duration: 90, price_policy: instrument_price_policy)
    est
  end

  before { login_as director }

  it "can edit an estimate" do
    visit facility_estimate_path(facility, estimate)
    expect(page).to have_content facility.to_s

    click_link "Edit"
    expect(page).to have_content "Edit Estimate"

    # The 2 items already added
    expect(page).to have_content("Remove", count: 2)

    fill_in "Name", with: "Updated Estimate Title"
    fill_in "Note", with: "Updated note text"
    fill_in "Expires at", with: 2.months.from_now.strftime("%m/%d/%Y")

    expect(page).to have_content "Add Products to Estimate"

    select_from_chosen other_item.name, from: "Product", scroll_to: :center
    click_button "Add Product to Estimate"

    wait_for_ajax

    # 1 more remove button for the new item
    expect(page).to have_content("Remove", count: 3)

    within '#estimate_estimate_details' do
      other_item_row = all('tr').last
      columns = other_item_row.all('td')
      first_column_text = columns[0].text
      expect(first_column_text).to eq other_item.name
    end

    within '#estimate_estimate_details' do
      first_row = all('tr').first
      columns = first_row.all('td')
      remove_button = columns[3].find('.remove-estimate-detail')
      remove_button.click

      first_row = all('tr').first
      columns = first_row.all('td')
      remove_button = columns[3].find('.remove-estimate-detail')
      remove_button.click
    end

    # we deleted 2 items so there are 2 remove button less
    expect(page).to have_content("Remove", count: 1)

    click_button "Update"

    expect(page).to have_content "Estimate was successfully updated"
    expect(page).to have_content "Estimate ##{estimate.id} - Updated Estimate Title"
    expect(page).to have_content "Updated note text"
    expect(page).to have_content 2.months.from_now.strftime("%m/%d/%Y")
    expect(page).to have_content director.full_name
    expect(page).to have_content user.full_name

    expect(page).not_to have_content item.name
    expect(page).not_to have_content instrument.name
    expect(page).to have_content other_item.name

    expect(page).to have_content ActionController::Base.helpers.number_to_currency(other_item_price_policy.unit_cost)
  end
end
