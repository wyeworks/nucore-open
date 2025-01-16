# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Launching Kiosk View", :js, :disable_requests_local, :show_rescuable_exceptions, feature_setting: { kiosk_view: true, bypass_kiosk_auth: false }  do
  let(:facility) { create(:setup_facility, kiosk_enabled: true) }
  let(:account) { create(:setup_account) }
  let!(:account_user) { FactoryBot.create(:account_user, :purchaser, account: account, user: user) }

  let(:order_detail) { FactoryBot.create(:setup_order, product: instrument, account: account).order_details.first }
  let(:instrument) { create(:setup_instrument, :timer, facility: facility) }

  shared_examples "kiosk_actions" do |login_label, password|
    context "with an admin reservation" do
      let!(:admin_reservation) { create(:admin_reservation, reserve_start_at: 15.minutes.ago, product: instrument) }
      let!(:accessory) { create(:accessory, parent: instrument) }

      it "does not error" do
        visit facility_kiosk_reservations_path(facility)

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("No user found")
        expect(page).to have_content(login_label)
      end
    end

    context "with an offline reservation" do
      let!(:offline_reservation) { create(:offline_reservation, reserve_start_at: 15.minutes.ago, product: instrument) }

      it "does not error" do
        visit facility_kiosk_reservations_path(facility)

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("No user found")
        expect(page).to have_content(login_label)
      end
    end

    context "with an active reservation that hasn't been started" do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, product: instrument, user: user) }

      it "can start reservations with a valid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "Begin Reservation"
        fill_in "Password", with: password
        click_button "Begin Reservation"

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("End Reservation")
        expect(page).to have_content(login_label)
      end

      it "cannot start reservations with an invalid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "Begin Reservation"
        fill_in "Password", with: "not-the-password"
        click_button "Begin Reservation"

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Invalid password")

        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Begin Reservation") # the reservation still hasn't started
        expect(page).to have_content(login_label)
      end
    end

    context "with an active reservation that is running" do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, actual_start_at: 10.minutes.ago, product: instrument, user: user) }

      it "can end reservations with a valid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        expect(page).not_to have_content("Add Accessories")
        click_link "End Reservation"
        fill_in "Password", with: password
        click_button "End Reservation"

        wait_for_ajax

        expect(page).not_to have_content("End Reservation")
        expect(page).not_to have_content("Begin Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
      end

      it "cannot end reservations with an invalid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "End Reservation"
        fill_in "Password", with: "not-the-password"
        click_button "End Reservation"

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Invalid password")

        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("End Reservation") # the reservation still hasn't started
        expect(page).to have_content(login_label)
      end
    end

    context "with an active reservation (with accessories) that is running" do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, actual_start_at: 10.minutes.ago, product: instrument, user: user, order_detail: order_detail) }
      let!(:accessory) { create(:accessory, parent: instrument) }

      it "can add accessories to reservations with a valid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "Add Accessories"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        fill_in "Password", with: password
        click_button "Save Changes"

        expect(page).to have_content("1 accessory added")
        expect(page).to have_content("End Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
      end

      it "cannot add accessories with an invalid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "Add Accessories"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        fill_in "Password", with: "not-the-password"
        click_button "Save Changes"
        expect(page).not_to have_content("1 accessory added")
        expect(page).to have_content("End Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
      end

      it "can add accessories when ending reservations with a valid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "End Reservation"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        fill_in "Password", with: password
        click_button "Save Changes"

        expect(page).not_to have_content("End Reservation")
        expect(page).not_to have_content("Begin Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
      end

      it "cannot end reservations with an invalid password" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content(login_label)
        click_link "End Reservation"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        fill_in "Password", with: "not-the-password"
        click_button "Save Changes"

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Invalid password")

        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("End Reservation") # the reservation still hasn't started
        expect(page).to have_content(login_label)
      end
    end
  end

  context "with an LDAP authenticated user", :ldap, ignore_js_errors: true, feature_setting: { kiosk_view: true, bypass_kiosk_auth: false, uses_ldap_authentication: true } do
    let(:user) { create(:user, :netid, :purchaser, account: account, email: "internal@example.org", username: "netid") }

    before(:each) do
      allow_any_instance_of(Users::AuthChecker).to receive(:ldap_enabled?).and_return(true)
    end

    it_behaves_like "kiosk_actions", "Login", "netidpassword"
  end

  context "with a locally authenticated user", ignore_js_errors: true do
    let(:user) { create(:user, :external, :purchaser, account: account) }

    it_behaves_like "kiosk_actions", "Login", "P@ssw0rd!!"

    it "has a list of instruments" do
      name1 = instrument.name
      name2 = create(:setup_instrument, :timer, facility: facility).name
      visit facility_kiosk_reservations_path(facility)
      timeline = find(".timeline-wrapper")

      expect(timeline).to have_content name1
      expect(timeline).to have_content name2
    end
  end

  context "with a locally authenticated user who is signed in", ignore_js_errors: true do
    let(:user) { create(:user, :external, :purchaser, account: account) }

    before { login_as(user) }

    it_behaves_like "kiosk_actions", "Logout", "P@ssw0rd!!"
  end

  context "with an SSO authenticated user", ignore_js_errors: true, feature_setting: { kiosk_view: true, bypass_kiosk_auth: true } do
    let(:user) { create(:user, :netid, :purchaser, account: account, email: "internal@example.org", username: "netid") }

    context "with an active reservation that hasn't been started" do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, product: instrument, user: user) }

      it "can start reservations (no password field)" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
        click_link "Begin Reservation"
        expect(page).not_to have_content("Password")
        click_button "Begin Reservation"

        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("End Reservation")
        expect(page).to have_content("Login")
      end
    end

    context "with an active reservation that is running", ignore_js_errors: true do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, actual_start_at: 10.minutes.ago, product: instrument, user: user) }

      it "can end reservations (no password field)" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
        expect(page).not_to have_content("Add Accessories")
        click_link "End Reservation"
        expect(page).not_to have_content("Password")
        click_button "End Reservation"

        expect(page).not_to have_content("End Reservation")
        expect(page).not_to have_content("Begin Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
      end
    end

    context "with an active reservation (with accessories) that is running" do
      let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, actual_start_at: 10.minutes.ago, product: instrument, user: user, order_detail: order_detail) }
      let!(:accessory) { create(:accessory, parent: instrument) }

      it "can add accessories (no password field)" do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
        click_link "Add Accessories"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        expect(page).not_to have_content("Password")
        click_button "Save Changes"

        expect(page).to have_content("1 accessory added")
        expect(page).to have_content("End Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
      end

      it "can add accessories when ending reservations (no password field)", ignore_js_errors: true do
        visit facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
        click_link "End Reservation"
        check accessory.name
        fill_in "kiosk_accessories_#{accessory.id}_quantity", with: "3"
        expect(page).not_to have_content("Password")
        click_button "Save Changes"

        expect(page).not_to have_content("End Reservation")
        expect(page).not_to have_content("Begin Reservation")
        expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
        expect(page).to have_content("Login")
      end
    end
  end

  context "with a facility that has disabled the kiosk view", ignore_js_errors: true do
    let(:user) { create(:user, :external, :purchaser, account: account) }
    let(:facility) { create(:setup_facility, kiosk_enabled: false) }
    let!(:reservation) { create(:purchased_reservation, reserve_start_at: 15.minutes.ago, product: instrument, user: user) }

    it "does not show the kiosk view" do
      visit facility_kiosk_reservations_path(facility)
      expect(page).to have_content("Login")
      expect(page).not_to have_content("Begin Reservation")
      expect(page).not_to have_content("End Reservation")
      expect(page.current_path).to eq new_user_session_path
    end
  end
end
