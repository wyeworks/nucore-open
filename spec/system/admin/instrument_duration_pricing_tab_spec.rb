# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Instrument Duration Pricing Tab" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:user) { FactoryBot.create(:user, :administrator) }

  before do
    login_as user
    visit edit_facility_instrument_duration_rate_path(facility, instrument)
  end

  context "the instrument has no duration pricing rules" do
    let!(:instrument) do
      FactoryBot.create(:setup_instrument, pricing_mode: "Duration")
    end

    it "renders the page" do
      expect(page).to have_content("Duration pricing rules determine the specific rate applied when using Duration pricing mode. You may define up to 4 duration pricing rules.")
    end

    context "adding new duration pricing rules" do
      it "shows 4 group of fields for duration rates" do
        expect(page).to have_field("duration_rates_attributes_0_min_duration")
        expect(page).to have_field("duration_rates_attributes_1_min_duration")
        expect(page).to have_field("duration_rates_attributes_2_min_duration")
        expect(page).to have_field("duration_rates_attributes_3_min_duration")
        expect(page).to have_field("duration_rates_attributes_0_rate")
        expect(page).to have_field("duration_rates_attributes_1_rate")
        expect(page).to have_field("duration_rates_attributes_2_rate")
        expect(page).to have_field("duration_rates_attributes_3_rate")
      end

      it "saves new duration pricing rules" do
        fill_in "duration_rates_attributes_0_min_duration", with: "3"
        fill_in "duration_rates_attributes_0_rate", with: "10.00"

        click_button "Save"
        instrument.reload
        expect(instrument.duration_rates).to be_present
        expect(instrument.duration_rates.length).to eq(1)
        expect(instrument.duration_rates.first.min_duration).to eq(3)
        expect(instrument.duration_rates.first.rate).to eq(10.00)

        expect(page).to have_content("The duration pricing rules have been updated")
      end

      context "two duration pricing with the same minimum duration" do
        it "shows an error" do
          fill_in "duration_rates_attributes_0_min_duration", with: "3"
          fill_in "duration_rates_attributes_0_rate", with: "10.00"
          fill_in "duration_rates_attributes_1_min_duration", with: "3"
          fill_in "duration_rates_attributes_1_rate", with: "11.00"

          click_button "Save"
          expect(page).to have_content("Minimum duration values must be unique")
        end
      end
    end
  end

end
