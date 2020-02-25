# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Orders Search" do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:user) { create(:user) }
  let(:instrument) { create(:setup_instrument, facility: facility) }
  let(:instrument2) { create(:setup_instrument, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }

  let!(:reservations) do
    [instrument, instrument2].map do |inst|
      create(:purchased_reservation, :later_today, product: inst, user: user)
    end
  end

  let!(:problem_reservations) do
    [instrument, instrument2].map do |inst|
      create(:completed_reservation, :yesterday, product: inst, user: user)
    end
  end

  context "new and in process orders tab" do
    it "can do a basic search" do
      login_as director
      visit facility_reservations_path(facility)

      select instrument.name, from: "Products"
      click_button "Filter"
      expect(page).to have_css(".order-detail-description", text: instrument.name, count: 1)
      expect(page).not_to have_css(".order-detail-description", text: instrument2.name)
    end
  end

  context "problem orders tab" do
    it "can do a basic search" do
      login_as director
      visit show_problems_facility_reservations_path(facility)

      select instrument.name, from: "Products"
      click_button "Filter"
      expect(page).to have_css("td", text: instrument.name, count: 1)
      expect(page).not_to have_css("td", text: instrument2.name)
    end
  end
end
