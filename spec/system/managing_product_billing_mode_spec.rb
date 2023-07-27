# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing products" do
  let(:instrument) { FactoryBot.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let(:administrator) { create(:user, :administrator) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility: facility) }
  let(:new_instrument) { FactoryBot.build(:instrument) }

  before do
    login_as user
    visit facility_instruments_path(facility)
  end

  context "global admin" do
    let(:user) { administrator }

    it "can select a billing mode when creating an instrument" do
      click_link "Add Instrument"
      fill_in "instrument[name]", with: new_instrument.name
      fill_in "instrument[url_name]", with: new_instrument.url_name
      select "Skip Review", from: "Billing mode"
      select "1", from: "Interval (minutes)"
      click_button "Create"
      expect(page).to have_content("Instrument was successfully created.")
      expect(page).to have_content("Skip Review")
    end

    it "cannot select a billing mode when editing an instrument" do
      click_link instrument.name
      expect(page).not_to have_content "Billing mode"
    end
  end

  context "non-global admin" do
    let(:user) { facility_administrator }

    it "cannot select a billing mode when creating an instrument" do
      click_link "Add Instrument"
      expect(page).not_to have_content "Billing mode"
    end
  end
end
