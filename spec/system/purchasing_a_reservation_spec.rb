# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchasing a reservation" do

  let!(:instrument) { FactoryBot.create(:setup_instrument, user_notes_field_mode: "optional") }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryBot.create(:user) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account:, price_group: price_policy.price_group)
  end

  before do
    facility.update(accepts_multi_add: true)
    login_as user
    visit facility_path(facility)
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
      expect(page).to have_content("Reserve Start must be in the future")
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

  describe "Reserving a hidden instrument" do
    let!(:instrument) { FactoryBot.create(:setup_instrument, user_notes_field_mode: "optional", is_hidden: true) }

    context "as a non-admin" do
      it "does NOT show the hidden instrument" do
        expect(page).not_to have_button("Create Order")
        expect(page).not_to have_content("Hidden")
      end
    end

    context "as an admin" do
      let(:user) { FactoryBot.create(:user, :facility_administrator, facility:) }

      it "shows the hidden instrument" do
        expect(page).to have_button("Create Order")
        expect(page).to have_content("Hidden")
      end
    end
  end

  describe "When the facility has no products" do
    let!(:instrument) { nil }
    let!(:price_policy) { nil }
    let!(:account_price_group_member) { nil }
    let!(:facility) { FactoryBot.create(:facility) }

    context "as a non-admin" do
      it "will not show the Create Order button" do
        expect(page).not_to have_button("Create Order")
      end
    end

    context "as an admin" do
      let(:user) { FactoryBot.create(:user, :facility_administrator, facility:) }

      it "will not show the Create Order button" do
        expect(page).not_to have_button("Create Order")
      end
    end
  end

  describe "new daily reservation" do
    let(:instrument) do
      create(
        :setup_instrument,
        :always_available,
        pricing_mode: Instrument::Pricing::SCHEDULE_DAILY
      )
    end
    let(:reservation_path) do
      new_facility_instrument_single_reservation_path(
        facility, instrument
      )
    end

    context "as user" do
      let(:user) { create(:user) }

      before do
        login_as user
      end

      include_examples "new daily reservation"

      context "when start time is fixed" do
        before do
          instrument.update(start_time_disabled: true)
        end

        include_examples "new daily reservation with start time disabled"
      end
    end

    context "as admin" do
      let(:success_message) do
        "The reservation was successfully created"
      end
      let(:admin_user) do
        create(
          :user,
          :facility_administrator,
          facility:
        )
      end
      let(:note) { "Some note about the reservation" }

      before do
        login_as admin_user

        visit facility_user_switch_to_path(facility, user)
      end

      include_examples(
        "new daily reservation",
        before_submit: proc do
          fill_in("reservation[note]", with: note)
        end,
        after_submit: proc do
          expect(page).to have_content(note)
          expect(user.reservations.count).to eq(1)
        end
      )

      context "when start time is fixed" do
        before do
          instrument.update(start_time_disabled: true)
        end

        include_examples(
          "new daily reservation with start time disabled",
          before_submit: proc do
            fill_in("reservation[note]", with: note)
          end,
          after_submit: proc do
            expect(page).to have_content(note)
            expect(user.reservations.count).to eq(1)
          end
        )
      end
    end

    context "on unavailable day" do
      let(:available_day) { 1.day.from_now.to_date }
      let(:unavailable_day) { 2.days.from_now.to_date }

      before do
        instrument.schedule_rules.destroy_all
        available_wday = Date::ABBR_DAYNAMES[available_day.wday].downcase
        unavailable_wday = Date::ABBR_DAYNAMES[unavailable_day.wday].downcase

        create(
          :schedule_rule,
          product: instrument,
          "on_#{available_wday}" => true,
          "on_#{unavailable_wday}" => false,
        )

        login_as user
      end

      it "cannot create reservation starting on unavailable day", :js do
        visit reservation_path

        fill_in("reservation[reserve_start_date]", with: I18n.l(unavailable_day, format: :usa))

        click_button("Create")

        expect(page).to have_content(
          I18n.t("activerecord.errors.models.reservation.attributes.base.no_schedule_rule")
        )
      end

      it "can create before unavailable day and span over it" do
        visit reservation_path

        fill_in("reservation[reserve_start_date]", with: I18n.l(available_day, format: :usa))
        fill_in("reservation[duration_days]", with: "2")

        click_button("Create")

        expect(page).to have_content("Reservation created successfully")
      end
    end
  end

  describe "honours cutoff hours" do
    let(:reserve_time) { 78.minutes.from_now }

    before do
      instrument.update!(cutoff_hours: 2)
    end

    it "cannot create a reservation after cutoff hours" do
      visit new_facility_instrument_single_reservation_path(facility, instrument)

      rounded_mins = reserve_time.min.then { |min| min - (min % instrument.reserve_interval) }

      select(format("%02d", reserve_time.hour), from: "reservation[reserve_start_hour]")
      select(format("%02d", rounded_mins), from: "reservation[reserve_start_min]")

      click_button("Create")

      expect(page).to have_content "Reserve Start must be at least 2 hours in the future"
    end
  end

  context "when there's no price group product for the user price group" do
    let(:other_price_group) do
      PriceGroup.where.not(id: user.price_groups.map(&:id)).first
    end

    before do
      instrument.price_group_products.where.not(
        price_group: other_price_group.id
      ).destroy_all
    end

    it "can navigate to the reservation page" do
      visit new_facility_instrument_single_reservation_path(facility, instrument)

      expect(page).to have_content("Create Reservation")
    end
  end

  describe "with accessories feature enabled", feature_setting: { add_accessories_before_reservation_starts: true } do
    let!(:accessory) { create(:accessory, parent: instrument) }

    it "shows accessories section and allows selection" do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"

      expect(page).to have_content "Add Accessories"
      expect(page).to have_content accessory.name

      check accessory.name

      quantity_field = find_field("accessories_#{accessory.id}_quantity")
      expect(quantity_field).not_to be_disabled
      expect(quantity_field.value).to eq "1"

      fill_in "accessories_#{accessory.id}_quantity", with: "3"

      click_button "Create"

      expect(page).to have_content "My Reservations"
      expect(Reservation.last.order_detail.child_order_details.first.product).to eq(accessory)
    end

    it "creates reservation without accessories when none selected" do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"

      expect(page).to have_content "Add Accessories"

      click_button "Create"

      expect(page).to have_content "My Reservations"
      expect(Reservation.last.order_detail.child_order_details.count).to eq(0)
    end

    describe "when acting as another user" do
      let(:admin) { create(:user, :facility_director, facility:) }

      before do
        login_as admin
        visit facility_users_path(facility)
        fill_in "search_term", with: user.email
        click_button "Search"
        click_link "Order For"
      end

      it "shows accessories section when acting as another user" do
        click_link instrument.name
        select user.accounts.first.description, from: "Payment Source"

        expect(page).to have_content "Add Accessories"
        expect(page).to have_content accessory.name
        expect(page).to have_content "You are ordering for #{user.full_name}"

        check accessory.name

        fill_in "accessories_#{accessory.id}_quantity", with: "3"

        click_button "Create"

        expect(page).to have_content "The reservation was successfully created"
        expect(Reservation.last.order_detail.child_order_details.first.product).to eq(accessory)
        expect(Reservation.last.order_detail.child_order_details.first.quantity).to eq(3)
      end
    end
  end
end
