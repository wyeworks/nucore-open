# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchasing a reservation on behalf of another user" do

  let!(:instrument) { FactoryBot.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument, start_date: 2.days.ago) }
  let(:user) { FactoryBot.create(:user) }
  let(:facility_admin) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    facility.update(accepts_multi_add: true)
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.email
    click_button "Search"
    click_link "Order For"
  end

  it "is now on the facility page" do
    expect(current_path).to eq(facility_path(facility))
    expect(page).to have_content("You are ordering for #{user.full_name}")
  end

  describe "and you create a reservation" do
    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      fill_in "Note", with: "A note"
      fill_in "Reference ID", with: "Ref123"
      click_button "Create"
    end

    it "returns to My Reservations" do
      expect(page).to have_content "Order Receipt"
    end

    it "has optional attributes set" do
      expect(Reservation.last.note).to eq("A note")
      expect(Reservation.last.reference_id).to eq("Ref123")
    end
  end

  describe "ordering over an administrative hold" do
    let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour) }

    describe "when you create a reservation" do
      it "can purchase" do
        click_link instrument.name

        # time is frozen to 9:30am ten days after fiscal year start, we expect the default time to be the end of the admin reservation
        expect(page.find_field("reservation_reserve_start_date").value).to eq Time.zone.today.strftime("%m/%d/%Y")
        expect(page.find_field("reservation_reserve_start_hour").value).to eq "11"
        expect(page.find_field("reservation_reserve_start_min").value).to eq "0"
        expect(page.find_field("reservation_reserve_start_meridian").value).to eq "AM"

        fill_in "Duration", with: 90
        select 10, from: "reservation_reserve_start_hour"
        select user.accounts.first.description, from: "Payment Source"
        click_button "Create"

        expect(page).to have_content "Order Receipt"
        expect(page).to have_content "Warning: You have scheduled over an administrative hold."
        expect(page).to have_content "10:00 AM - 11:30 AM"
      end
    end
  end

  describe "when the user is not authorized" do
    before do
      instrument.update!(requires_approval: true)
    end

    it "can purchase" do
      click_link instrument.name
      expect(page).to have_content("The user you are ordering for is not on the authorized list for this instrument.")
      select user.accounts.first.description, from: "Payment Source"

      click_button "Create"

      expect(page).to have_content("Order Receipt")
    end
  end

  describe "creating multiple reservations" do
    it "can create reservations in the future" do
      fill_in "order[order_details][][quantity]", with: "2"
      click_button "Create Order", match: :first
      choose account.to_s
      click_button "Continue"

      click_link "Make a Reservation", match: :first
      fill_in "Reserve Start", with: I18n.l(1.day.from_now.to_date, format: :usa)
      click_button "Create"

      all(:link, "Make a Reservation").last.click
      fill_in "Reserve Start", with: I18n.l(2.days.from_now.to_date, format: :usa)
      click_button "Create"

      click_button "Purchase"

      expect(page).to have_content "Order Receipt"
      expect(page).to have_css(".currency .estimated_cost", count: 4) # Cost and Total x 2 orders
      expect(page).to have_css(".currency .actual_cost", count: 0)
    end

    it "can create reservations in the past" do
      fill_in "order[order_details][][quantity]", with: "2"
      click_button "Create Order", match: :first
      choose account.to_s
      click_button "Continue"

      click_link "Make a Reservation", match: :first
      fill_in "Reserve Start", with: I18n.l(1.day.ago.to_date, format: :usa)
      click_button "Create"

      all(:link, "Make a Reservation").last.click
      fill_in "Reserve Start", with: I18n.l(2.days.ago.to_date, format: :usa)
      click_button "Create"

      click_button "Purchase"

      expect(page).to have_content "Order Receipt"
      expect(page).to have_css(".currency .estimated_cost", count: 0)
      expect(page).to have_css(".currency .actual_cost", count: 4) # Cost and Total x 2 orders
    end

    it "can modify a reservation in the future" do
      fill_in "order[order_details][][quantity]", with: "2"
      click_button "Create Order", match: :first
      choose account.to_s
      click_button "Continue"

      click_link "Make a Reservation", match: :first
      fill_in "Reserve Start", with: I18n.l(1.day.from_now.to_date, format: :usa)
      select "10", from: "reservation[reserve_start_hour]"
      select "00", from: "reservation[reserve_start_min]"
      fill_in "Duration", with: "90"
      click_button "Create"

      reservation_time = "#{1.day.from_now.strftime('%m/%d/%Y')} 10:00 AM - 11:30 AM"
      expect(page).to have_content(reservation_time)
      click_link reservation_time

      select "11", from: "reservation[reserve_start_hour]"
      click_button "Save"
      expect(page).to have_content("#{1.day.from_now.strftime('%m/%d/%Y')} 11:00 AM - 12:30 PM")
    end

    it "can modify a reservation in the past" do
      fill_in "order[order_details][][quantity]", with: "2"
      click_button "Create Order", match: :first
      choose account.to_s
      click_button "Continue"

      click_link "Make a Reservation", match: :first
      fill_in "Reserve Start", with: I18n.l(1.day.ago.to_date, format: :usa)
      select "10", from: "reservation[reserve_start_hour]"
      select "00", from: "reservation[reserve_start_min]"
      fill_in "Duration", with: "90"
      click_button "Create"

      reservation_time = "#{1.day.ago.strftime('%m/%d/%Y')} 10:00 AM - 11:30 AM"
      expect(page).to have_content(reservation_time)
      click_link reservation_time

      select "11", from: "reservation[reserve_start_hour]"
      click_button "Save"
      expect(page).to have_content("#{1.day.ago.strftime('%m/%d/%Y')} 11:00 AM - 12:30 PM")
    end
  end
end
