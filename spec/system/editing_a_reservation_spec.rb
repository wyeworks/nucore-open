# frozen_string_literal: true

require "rails_helper"

# TODO: Capybara deprecation
RSpec.describe "Editing your own reservation" do
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

    it "shows current reservation", :js do
      visit reservations_path
      click_link reservation.to_s

      expect(page).to have_css(".current-event", text: "My Reservation")
    end

    it "allows me to move and shorten the reservation" do
      visit reservations_path
      click_link reservation.to_s

      fill_in "Reserve Start", with: SpecDateHelper.format_usa_date(reservation.reserve_start_at + 1.hour)
      fill_in "Reserve End", with: SpecDateHelper.format_usa_date(reservation.reserve_end_at + 1.hour)
      fill_in "Duration", with: "30"
      click_button "Save"

      expect(reservation.reload.duration_mins).to eq(30)
    end

    it "allows me to move the reservation into the lock window" do
      visit reservations_path
      click_link reservation.to_s

      fill_in "Reserve Start", with: SpecDateHelper.format_usa_date(reservation.reserve_start_at - 1.day)
      fill_in "Reserve End", with: SpecDateHelper.format_usa_date(reservation.reserve_end_at - 1.day)
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

  describe "with a daily booking instrument" do
    let(:today) { Time.current.beginning_of_day }
    let(:unavailable_period_start) { today + 3.days }
    let(:instrument) do
      create(
        :setup_instrument,
        :always_available,
        :daily_booking,
      )
    end
    let!(:reservation) do
      create(
        :purchased_reservation,
        user:,
        reserve_start_at: today + 10.days,
        reserve_end_at: today + 11.days,
        product: instrument,
      )
    end
    let!(:other_reservation) do
      create(
        :purchased_reservation,
        user: create(:user),
        reserve_start_at: today + 1.day,
        reserve_end_at: today + 2.days,
        product: instrument,
      )
    end

    it "shows current reservation", :js do
      visit reservations_path
      click_link reservation.to_s

      expect(page).to have_css(".current-event", text: "My Reservation")

      fill_in("Duration", with: "10")

      click_button "Save"

      expect(page).to have_content(I18n.t("controllers.reservations.update.success"))
    end

    def move_reservation
      visit reservations_path

      expect(page).to have_content("Move Up")

      click_link("Move Up")

      expect(page).to have_content("Would you like to move your reservation?")

      click_button("Move")

      expect(page).to have_content("The reservation was moved successfully")

      expect(page).to_not have_content("Move Up")
    end

    shared_examples "unavailable due to reason" do |error_key|
      it "fail to create a new reservation in the unavailable day" do
        new_reserve_start_at = unavailable_period_start + 1.minute
        invalid_reservation = build(
          :purchased_reservation,
          user:,
          reserve_start_at: new_reserve_start_at,
          reserve_end_at: new_reserve_start_at + 1.day,
          product: instrument
        )

        expect(invalid_reservation).to_not be_valid
        expect(invalid_reservation.errors).to be_added(:base, error_key)
      end
    end

    context "when unavailable due to schedule rule" do
      before do
        # Disable schedule rule on unavailable day
        reservation.product.schedule_rules.first.then do |schedule_rule|
          wday = unavailable_period_start.wday
          wday_name = Date::ABBR_DAYNAMES[wday].downcase
          schedule_rule.update("on_#{wday_name}" => false)
        end
      end

      include_examples "unavailable due to reason", :no_schedule_rule

      context "when the reservation last 1 day" do
        it "moves just before unavailable day" do
          move_reservation

          # Move the reservation right after other reservation
          expect(reservation.reload.reserve_start_at).to(
            eq(other_reservation.reserve_end_at)
          )
        end
      end

      context "when the reservation lasts 20 days" do
        before do
          reservation.update_attribute(
            :reserve_end_at, reservation.reserve_start_at + 20.days
          )
        end

        it "moves just before unavailable day" do
          move_reservation

          # Move the reservation right after other reservation
          expect(reservation.reload.reserve_start_at).to(
            eq(other_reservation.reserve_end_at)
          )
        end
      end
    end

    context "when unavailable due to a reservation" do
      let!(:conflict_reservation) do
        create(
          :purchased_reservation,
          user: create(:user),
          reserve_start_at: unavailable_period_start,
          reserve_end_at: unavailable_period_start + 1.day,
          product: instrument,
        )
      end

      include_examples "unavailable due to reason", :conflict

      context "when the reservation's duration is 1 day" do
        it "moves the reservation before the unavailable" do
          move_reservation

          # Move the reservation just in between other reservation and
          # unavailable period
          expect(reservation.reload.reserve_start_at).to eq(
            other_reservation.reserve_end_at
          )
          expect(reservation.reserve_end_at).to eq unavailable_period_start
        end
      end

      context "when the reservation's duration is 20 days" do
        before do
          reservation.update_attribute(
            :reserve_end_at, reservation.reserve_start_at + 20.days
          )
        end

        it "moves the reservation before the unavailable" do
          move_reservation

          # Move the reservation just in between other reservation and
          # unavailable period
          expect(reservation.reload.reserve_start_at).to eq(
            conflict_reservation.reserve_end_at
          )
        end
      end
    end
  end
end
