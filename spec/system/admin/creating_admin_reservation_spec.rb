# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an admin reservation" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }
  let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility) }

  before { login_as director }
  let(:fiscal_year) { SettingsHelper.fiscal_year_beginning.year }

  it "renders native date inputs" do
    visit new_facility_instrument_reservation_path(facility, instrument)

    expect(page).to have_css("input[type='date'][name='admin_reservation[reserve_start_date]']")
    expect(page).to have_css("input[type='date'][name='admin_reservation[reserve_end_date]']")
    expect(page).to have_css("input[type='date'][name='admin_reservation[repeat_end_date]']")
  end

  it "can place an admin reservation" do
    visit new_facility_instrument_reservation_path(facility, instrument)

    fill_in "Reserve start date", with: Date.new(fiscal_year, 10, 17)
    fill_in "Duration mins", with: "30"
    click_button "Create"

    expect(page).to have_content "10/17/#{fiscal_year} 9:30 AM - 10:00 AM"
  end

  it "can place recurring admin reservations" do
    visit new_facility_instrument_reservation_path(facility, instrument)

    fill_in "Reserve start date", with: Date.new(fiscal_year, 10, 17)
    fill_in "Duration mins", with: "30"
    check "Repeats"
    select "Daily", from: "Repeat frequency"
    fill_in "Repeat end date", with: Date.new(fiscal_year, 10, 20)
    click_button "Create"

    expect(page).to have_content "10/17/#{fiscal_year} 9:30 AM - 10:00 AM"
    expect(page).to have_content "10/18/#{fiscal_year} 9:30 AM - 10:00 AM"
    expect(page).to have_content "10/19/#{fiscal_year} 9:30 AM - 10:00 AM"
    expect(page).to have_content "10/20/#{fiscal_year} 9:30 AM - 10:00 AM"
  end

end
