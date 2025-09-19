# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reserving an instrument using quick reservations", feature_setting: { walkup_reservations: true, reload_routes: true, user_based_price_groups: true } do
  include ResearchSafetyTestHelpers

  let(:user) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:admin_user) { create(:user, :administrator) }
  let!(:instrument) { create(:setup_instrument, :timer, min_reserve_mins: 5, user_notes_field_mode: "optional") }
  let!(:product_user) {}
  let(:intervals) { instrument.quick_reservation_intervals }
  let(:facility) { instrument.facility }
  let(:research_safety_certificate) { create(:research_safety_certificate) }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let!(:reservation) {}

  before do
    login_as user
    visit new_facility_instrument_quick_reservation_path(facility, instrument)
  end

  it "is accessible", :js do
    skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
    expect(page).to be_axe_clean
  end

  context "when there is no current reservation" do
    it "can start a reservation right now" do
      choose "30 mins"
      click_button "Create Reservation"
      expect(page).to have_content("9:31 AM - 10:01 AM")
      expect(page).to have_content("End Reservation")
      expect(page).to have_content("Report an Issue")
    end

    context "with accessories feature enabled", feature_setting: { add_accessories_before_reservation_starts: true } do
      let!(:accessory) { create(:accessory, parent: instrument) }

      before do
        instrument.reload
        visit new_facility_instrument_quick_reservation_path(facility, instrument)
      end

      it "shows accessories section and allows selection" do
        expect(page).to have_content "Add Accessories"
        expect(page).to have_content accessory.name

        check accessory.name

        quantity_field = find_field("accessories_#{accessory.id}_quantity")
        expect(quantity_field).not_to be_disabled
        expect(quantity_field.value).to eq "1"

        fill_in "accessories_#{accessory.id}_quantity", with: "3"

        choose "30 mins"
        click_button "Create Reservation"

        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
        expect(Reservation.last.order_detail.child_order_details.first.product).to eq(accessory)
        expect(Reservation.last.order_detail.child_order_details.first.quantity).to eq(3)
      end
    end

    context "with accessories feature disabled", feature_setting: { add_accessories_before_reservation_starts: false } do
      let!(:accessory) { create(:accessory, parent: instrument) }

      it "does not show accessories section" do
        expect(page).not_to have_content "Add Accessories"
        expect(page).not_to have_content accessory.name

        choose "30 mins"
        click_button "Create Reservation"

        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
        expect(Reservation.last.order_detail.child_order_details.count).to eq(0)
      end
    end
  end

  context "when the user has a future reservation" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user:,
        reserve_start_at: 1.hour.from_now,
        reserve_end_at: 1.hour.from_now + 30.minutes
      )
    end

    it "can move up and start their reservation" do
      click_button "Start Reservation"
      expect(page).to have_content("9:31 AM - 10:01 AM")
      expect(page).to have_content("End Reservation")
    end
  end

  context "when the user has a future reservation that cannot be started yet" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user,
        reserve_start_at: 30.minutes.from_now,
        reserve_end_at: 90.minutes.from_now
      )
    end

    let!(:reservation2) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user_2,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 30.minutes.from_now
      )
    end

    it "cannot start the reservation" do
      visit facility_instrument_quick_reservation_path(facility, instrument, reservation)
      expect(page).to have_content("Come back closer to reservation time to start your reservation")
    end
  end

  context "when the user has an ongoing reservation" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user:,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 1.hour.from_now
      )
    end

    it "can stop the reservation" do
      expect(page).to have_content("9:00 AM - 10:30 AM")
      click_link("End Reservation")
      expect(page).to have_content("The instrument has been deactivated successfully")
    end
  end

  context "when the user has an ongoing, complete reservation" do
    let!(:reservation) do
      r = create(
        :purchased_reservation,
        product: instrument,
        user:,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 5.minutes.ago
      )

      od = r.order_detail

      od.change_status!(OrderStatus.in_process)
      od.change_status!(OrderStatus.complete)
      od.save
    end

    it "does not redirect to the reservation" do
      expect(page).to have_current_path(new_facility_instrument_quick_reservation_path(facility, instrument))
    end
  end

  context "when another reservation exists in the future" do
    let(:start_at) {}
    let(:end_at) { start_at + 30.minutes }

    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user_2,
        reserve_start_at: start_at,
        reserve_end_at: end_at
      )
    end

    context "when the reservation is outside of all the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals.last.minutes + 5.minutes }

      it "can start a reservation right now" do
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to have_content("60 mins")
        choose "60 mins"
        fill_in "reservation[note]", with: "This is a note"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:31 AM")
        expect(page).to have_content("End Reservation")
      end
    end

    context "when the reservation is ouside only 2 of the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals[1].minutes + 5.minutes }

      it "can start a reservation right now" do
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to_not have_content("60 mins")
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
      end
    end

    context "when the reservation is inside all of the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals.first.minutes - 5.minutes }

      it "can create a reservation for later on" do
        expect(page).to have_content("The next available start time is")
        expect(page).to have_content("Reservation Time 10:10 AM")
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to have_content("60 mins")
      end
    end

    context "when the product requires a note" do
      let(:start_at) { Time.current + intervals.first.minutes - 5.minutes }
      let(:instrument) { create(:setup_instrument, :timer, min_reserve_mins: 5, user_notes_field_mode: "required") }

      it "can create a reservation when note is provided" do
        choose "60 mins"
        click_button "Create Reservation"
        expect(page).to have_content("Note may not be blank")
        choose "60 mins"
        fill_in "reservation[note]", with: "This is a note"
        click_button "Create Reservation"
        expect(page).to have_content("10:10 AM - 11:10 AM")
      end
    end
  end

  context "when another reservation is ongoing but abandoned" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user_2,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 15.minutes.ago
      )
    end

    it "can start a reservaton right now, and move the abandoned reservation into the problem queue" do
      choose "30 mins"
      click_button "Create Reservation"
      expect(page).to have_content("9:31 AM - 10:01 AM")
      expect(page).to have_content("End Reservation")
      # test that the abandoned reservation goes into the problem queue
      visit root_path
      click_link "Logout"
      login_as admin_user
      visit show_problems_facility_reservations_path(facility)
      expect(page).to have_content(reservation.order.id)
      expect(page).to have_content("Missing Actuals")
    end
  end

  context "when the instrument requires training" do
    let!(:certification_requirement) do
      ProductResearchSafetyCertificationRequirement.create(
        product: instrument,
        research_safety_certificate: research_safety_certificate,
      )
    end

    context "when the user does not have the required training" do
      before do
        stub_research_safety_lookup(user, invalid: [research_safety_certificate])
      end

      it "cannot start a reservation" do
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("Validation failed: Missing Certificates: #{research_safety_certificate.name}. Please contact your Research Safety program to complete your training.")
      end
    end

    context "when the user does have the required training" do
      before do
        stub_research_safety_lookup(user, valid: [research_safety_certificate], number_of_times: 2)
      end

      it "can start a reservation right now" do
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
      end
    end
  end

  context "when the user has no payment sources" do
    let!(:account) {}

    it "cannot create a reservation" do
      expect(page).not_to have_content("Create Reservation")

      if SettingsHelper.feature_on?(:user_based_price_groups_exclude_purchaser)
        expect(page).to have_content("No price groups found for this reservation")
      else
        expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to reserve this instrument")
      end
    end
  end

  context "when the instrument has an access list" do
    let!(:instrument) { create(:instrument_requiring_approval, :timer, min_reserve_mins: 5) }

    context "when a non-admin user is on the list" do
      let!(:product_user) { create(:product_user, product: instrument, user: user) }

      it "can start a reservation right now" do
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
      end
    end

    context "when a non-admin user is NOT on the list" do
      it "cannot create a reservation" do
        expect(page).not_to have_content("Create Reservation")
        expect(page).to have_content("This instrument requires approval to purchase")
      end
    end

    context "when an admin user is NOT on the list" do
      let(:user) { admin_user }

      it "can start a reservation right now" do
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
      end
    end
  end

  context "when the insturment has no schedule rules" do
    let!(:instrument) do
      create(:setup_instrument, :timer, min_reserve_mins: 5, skip_schedule_rules: true)
    end

    it "shows an error message" do
      expect(page).to have_content(I18n.t("models.instrument_for_cart.schedule_not_available"))
    end
  end
end
