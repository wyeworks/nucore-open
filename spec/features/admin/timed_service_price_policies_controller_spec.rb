# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimedServicePricePoliciesController, :js do
  let(:facility) { create(:setup_facility) }
  let!(:timed_service) { create(:timed_service, facility: facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }

  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let!(:cancer_center) { create(:price_group, :cancer_center) }

  before do
    login_as director
    facility.price_groups.destroy_all # get rid of the price groups created by the factories
  end

  it "can set up price policies" do
    visit facility_timed_services_path(facility, timed_service)
    click_link timed_service.name
    click_link "Pricing"
    click_link "Add Pricing Rules"

    fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "120.00"
    fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "25.25"
    fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "125.15"

    click_button "Add Pricing Rules"

    expect(page).to have_content("$2.0000 / minute") # Base rate
    expect(page).to have_content("$120.00\n- $25.25\n= $94.75") # Cancer center
    expect(page).to have_content("$1.5792 / minute") # Cancer center
    expect(page).to have_content("$2.0858 / minute") # External
  end

  it "can allow only some groups to purchase" do
    visit facility_timed_services_path(facility, timed_service)
    click_link timed_service.name
    click_link "Pricing"
    click_link "Add Pricing Rules"

    fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "100.00"
    fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "25.25"
    uncheck "price_policy_#{external_price_group.id}[can_purchase]"

    click_button "Add Pricing Rules"

    expect(page).to have_content(base_price_group.name)
    expect(page).to have_content(cancer_center.name)
    expect(page).not_to have_content(external_price_group.name)
  end
end
