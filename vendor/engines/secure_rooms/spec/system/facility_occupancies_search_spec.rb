# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Orders Search" do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price, facility: facility) }
  let(:secure_room2) { create(:secure_room, :with_schedule_rule, :with_base_price, facility: facility) }
  let(:account) { create(:setup_account) }
  let(:user) { account.owner_user }

  let!(:occupancies) do
    [secure_room, secure_room2].map do |room|
      create(:occupancy, :with_entry, :with_order_detail, secure_room: room, user: user, account: account)
    end
  end

  let!(:problem_occupancies) do
    [secure_room, secure_room2].map do |room|
      create(:occupancy, :problem_with_order_detail, secure_room: room, user: user, account: account)
    end
  end

  context "new and in process orders tab" do
    it "can do a basic search" do
      login_as director
      visit facility_occupancies_path(facility)

      select secure_room.to_s, from: "Products"
      click_button "Filter"
      expect(page).to have_css(".order-detail-description", text: secure_room.name, count: 1)
      expect(page).not_to have_css(".order-detail-description", text: secure_room2.name)
    end
  end

  context "problem orders tab" do
    it "can do a basic search" do
      login_as director
      visit show_problems_facility_occupancies_path(facility)

      select secure_room.to_s, from: "Products"
      click_button "Filter"
      expect(page).to have_css("td", text: secure_room.name, count: 1)
      expect(page).not_to have_css("td", text: secure_room2.name)
    end
  end
end
