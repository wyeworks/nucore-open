# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchasing a reservation" do

  let!(:instrument) { FactoryBot.create(:setup_instrument, user_notes_field_mode: "optional") }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryBot.create(:user) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    facility.update(accepts_multi_add: true)
    login_as user
    visit root_path
    click_link facility.name
  end

  describe "selecting the default time" do
    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      fill_in "Note", with: "A note about my reservation"
      click_button "Create"
    end

    it "is on the My Reservations page" do
      expect(page).to have_content "My Reservations"
      expect(page).to have_content "Note: A note about my reservation"
    end
  end

  describe "attempting to order in the past", :time_travel do
    let(:now) { Time.zone.local(2016, 8, 20, 11, 0) }

    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      select "10", from: "reservation[reserve_start_hour]"
      select "10", from: "reservation[reserve_end_hour]"
      click_button "Create"
    end

    it "has an error" do
      expect(page).to have_content "must be in the future"
    end
  end

  describe "trying to order with a required note" do
    before do
      instrument.update!(
        user_notes_field_mode: "required",
        user_notes_label: "Show me what you got",
      )
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
    end

    it "does not create the reservation without a note" do
      click_button "Create"
      expect(page).to have_content "Note may not be blank"

      fill_in "Show me what you got", with: "This is my note."
      click_button "Create"

      expect(page).to have_content("My Reservations")
    end

  end

  describe "ordering over an administrative hold" do

    describe "when you create a reservation" do
      context "admin hold is not expired" do
        let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour) }

        it "cannot purchase" do
          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"

          # time is frozen to 9:30am, we expect the default time to be the end of the admin reservation
          expect(page.find_field("reservation_reserve_start_date").value).to eq Time.zone.today.strftime("%m/%d/%Y")
          expect(page.find_field("reservation_reserve_start_hour").value).to eq "11"
          expect(page.find_field("reservation_reserve_start_min").value).to eq "0"
          expect(page.find_field("reservation_reserve_start_meridian").value).to eq "AM"

          fill_in "Duration", with: 90
          select 10, from: "reservation_reserve_start_hour"
          select user.accounts.first.description, from: "Payment Source"
          click_button "Create"

          expect(page).to have_content "The reservation conflicts with another reservation."
        end
      end

      context "admin hold is expired" do
        let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour, deleted_at: 1.hour.ago) }

        it "can purchase" do

          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"
          fill_in "Duration", with: 90
          select 10, from: "reservation_reserve_start_hour"
          select user.accounts.first.description, from: "Payment Source"
          click_button "Create"

          expect(page).to have_content "Reservation created successfully"
        end
      end
    end

  end

  it "clicking 'cancel' returns you to the facility page" do
    click_link instrument.name
    click_link "Cancel"

    expect(current_path).to eq(facility_path(facility))
  end

  describe "ordering on an order form" do
    before do
      fill_in "order[order_details][][quantity]", with: "2"
      click_button "Create Order", match: :first
      choose account.to_s
      click_button "Continue"
    end

    it "can place a reservation in the future and then edit it" do
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

    it "cannot place a reservtion in the past" do
      click_link "Make a Reservation", match: :first
      fill_in "Reserve Start", with: I18n.l(1.day.ago.to_date, format: :usa)
      select "10", from: "reservation[reserve_start_hour]"
      select "00", from: "reservation[reserve_start_min]"
      fill_in "Duration", with: "90"
      click_button "Create"
      expect(page).to have_content("Reserve start at must be in the future")
    end

    it "clicking cancel returns you to the cart as it was" do
      expect(page).to have_selector("h1", text: "Cart")
      cart_path = current_path # should be the cart_path
      click_link "Make a Reservation", match: :first
      click_link "Cancel"

      expect(current_path).to eq(cart_path)
      expect(page).to have_selector("h1", text: "Cart")
      expect(page).to have_link("Make a Reservation", count: 2)
    end
  end
end
