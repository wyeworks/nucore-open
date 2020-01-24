# frozen_string_literal: true

require "rails_helper"

# TODO: Capybara deprecation
RSpec.describe "Editing your own reservation" do

  include DateHelper

  let!(:instrument) do
    FactoryBot.create(:setup_instrument, user_notes_field_mode: "optional", lock_window: 12, min_reserve_mins: nil)
  end
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryBot.create(:user) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    login_as user
  end

  describe "a future reservation outside the lock windown" do
    # 9:30-10:30am
    let!(:reservation) { create(:purchased_reservation, :tomorrow, product: instrument, user: user) }

    it "allows me to move and shorten the reservation" do
      visit reservations_path
      click_link reservation.to_s

      fill_in "Reserve Start", with: format_usa_date(reservation.reserve_start_at + 1.hour)
      fill_in "Reserve End", with: format_usa_date(reservation.reserve_end_at + 1.hour)
      fill_in "Duration", with: "30"
      click_button "Save"

      expect(reservation.reload.duration_mins).to eq(30)
    end

    it "allows me to move the reservation into the lock window" do
      visit reservations_path
      click_link reservation.to_s

      fill_in "Reserve Start", with: format_usa_date(reservation.reserve_start_at - 1.day)
      fill_in "Reserve End", with: format_usa_date(reservation.reserve_end_at - 1.day)
      click_button "Save"

      expect(page).to have_content("My Reservations")
    end
  end

  describe "a reservation inside the lock window" do
    # Two hours from now
    let!(:reservation) { create(:purchased_reservation, :later_today, product: instrument, user: user) }

    it "prevents me from changing the start date, allows me to extend the reservation, but not shorten it" do
      visit reservations_path
      click_link reservation.to_s

      expect(page).to have_field("Reserve Start", disabled: true)
      fill_in "Duration", with: "90"
      click_button "Save"

      expect(page).to have_content("My Reservations")
      expect(reservation.reload.duration_mins).to eq(90)

      click_link reservation.to_s
      fill_in "Duration", with: "75"
      click_button "Save"

      expect(page).to have_content "cannot be shortened inside the lock window"
    end
  end

  describe "a started reservation" do
    let!(:reservation) { create(:purchased_reservation, :running, product: instrument, user: user) }

    it "prevents me from changing the start date, allows me to extend the reservation, but not shorten it" do
      visit reservations_path
      click_link reservation.to_s

      expect(page).to have_field("Reserve Start", disabled: true)
      fill_in "Duration", with: "90"
      click_button "Save"

      expect(page).to have_content("My Reservations")
      expect(reservation.reload.duration_mins).to eq(90)

      click_link reservation.to_s
      fill_in "Duration", with: "75"
      click_button "Save"

      expect(page).to have_content "cannot be shortened once the reservation has started"
    end
  end
end
