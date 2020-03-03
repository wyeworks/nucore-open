# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemPricePoliciesController, :js do
  let(:facility) { create(:setup_facility) }
  let!(:item) { create(:item, facility: facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }

  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let!(:cancer_center) { create(:price_group, :cancer_center) }

  before do
    login_as director
    facility.price_groups.destroy_all # get rid of the price groups created by the factories
  end

  it "can set up price policies", feature_setting: { facility_directors_can_manage_price_groups: true }  do
    visit facility_items_path(facility, item)
    click_link item.name
    click_link "Pricing"
    click_link "Add Pricing Rules"

    fill_in "price_policy_#{base_price_group.id}[unit_cost]", with: "100.00"
    fill_in "price_policy_#{cancer_center.id}[unit_subsidy]", with: "25.25"
    fill_in "price_policy_#{external_price_group.id}[unit_cost]", with: "125.15"

    fill_in "Note", with: "This is my note"

    click_button "Add Pricing Rules"

    expect(page).to have_content(table_row("#{base_price_group.name} (Internal)", "$100.00", "$0.00", "$100.00"))
    expect(page).to have_content(table_row("#{cancer_center.name} (Internal)", "$100.00", "$25.25", "$74.75"))
    expect(page).to have_content(table_row("#{external_price_group.name} (External)", "$125.15", "$0.00", "$125.15"))

    expect(page).to have_content("This is my note")
  end

  it "can allow only some groups to purchase", feature_setting: { facility_directors_can_manage_price_groups: true }  do
    visit facility_items_path(facility, item)
    click_link item.name
    click_link "Pricing"
    click_link "Add Pricing Rules"

    fill_in "Note", with: "This is my note"

    fill_in "price_policy_#{base_price_group.id}[unit_cost]", with: "100.00"
    fill_in "price_policy_#{cancer_center.id}[unit_subsidy]", with: "25.25"
    uncheck "price_policy_#{external_price_group.id}[can_purchase]"

    click_button "Add Pricing Rules"

    expect(page).to have_content(base_price_group.name)
    expect(page).to have_content(cancer_center.name)
    expect(page).not_to have_content(external_price_group.name)
  end

  describe "with required note enabled", feature_setting: { price_policy_requires_note: true, facility_directors_can_manage_price_groups: true } do
    it "requires the field" do
      visit facility_items_path(facility, item)
      click_link item.name
      click_link "Pricing"
      click_link "Add Pricing Rules"

      click_button "Add Pricing Rules"
      expect(page).to have_content("Note may not be blank")
    end
  end

  def table_row(*columns)
    columns.join(" ")
  end
end
