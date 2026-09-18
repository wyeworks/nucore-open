# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FacilityReservationsController" do
  describe "destroy" do
    let(:facility) { create(:setup_facility) }
    let(:instrument) { create(:setup_instrument, facility:) }
    let(:director) { create(:user, :facility_director, facility:) }
    let(:reservation) { create(:admin_reservation, product: instrument) }
    let(:service_spy) { instance_spy(ProductNotifications::SlotAvailableService) }
    let(:action) do
      lambda do |reservation|
        delete facility_instrument_reservation_path(facility, instrument, reservation)
      end
    end

    before do
      login_as director

      allow(ProductNotifications::SlotAvailableService).to receive(:from_reservation).and_return(service_spy)
    end

    it "calls SlotAvailableService with the reservation" do
      action.call(reservation)

      expect(ProductNotifications::SlotAvailableService).to(
        have_received(:from_reservation).with(reservation)
      )
    end

    it "calls notify_later on the service" do
      action.call(reservation)

      expect(service_spy).to have_received(:notify_later)
    end

    it "sets a success notice" do
      action.call(reservation)

      expect(flash[:notice]).to eq("The reservation has been removed successfully")
    end

    it "redirects to the instrument schedule" do
      action.call(reservation)

      expect(response).to redirect_to(
        facility_instrument_schedule_url(facility, instrument),
      )
    end

    it "destroys the reservation" do
      reservation

      expect do
        action.call(reservation)
      end.to change(Reservation, :count).by(-1)
    end

    context "when reservation has an order" do
      let(:reservation_with_order) do
        create(:purchased_reservation, product: instrument)
      end

      it "returns forbidden when reservation has an order detail (not admin)" do
        action.call(reservation_with_order)

        expect(response).to have_http_status(:forbidden)
        expect(ProductNotifications::SlotAvailableService).not_to have_received(:from_reservation)
      end
    end
  end

  describe "timeline relay controls" do
    let(:facility) { create(:setup_facility) }
    let(:instrument) { create(:setup_instrument, facility:) }
    let!(:relay) { create(:relay_syna, instrument:) }
    let(:user) { create(:user) }
    let(:facility_user_permission) { user.facility_user_permissions.find_by(facility:) }
    let(:toggle) { "#relay_#{instrument.id}" }
    let(:action) do
      lambda do |params = {}|
        get timeline_facility_reservations_path(facility, **params)
      end
    end

    before do
      user.facility_user_permissions.create(facility:, read_access: true)

      login_as user
    end

    context "with the instrument management permission" do
      before { facility_user_permission.update(instrument_management: true) }

      it "renders a switchable toggle" do
        action.call

        expect(page).to have_css("#{toggle}[data-relay-url]")
        expect(page).to have_no_css("#{toggle}[data-readonly]")
      end

      it "renders the refresh buttons" do
        action.call

        expect(page).to have_css(".relay_refresh_btn[data-instrument-id='#{instrument.id}']")
        expect(page).to have_css("#refresh_all_relays")
      end
    end

    context "without the instrument management permission" do
      it "renders the toggle as read-only" do
        action.call

        expect(page).to have_css("#{toggle}[data-readonly][disabled]")
        expect(page).to have_no_css("#{toggle}[data-relay-url]")
      end

      it "still renders the refresh buttons" do
        action.call

        expect(page).to have_css(".relay_refresh_btn[data-instrument-id='#{instrument.id}']")
        expect(page).to have_css("#refresh_all_relays")
      end
    end

    context "when the date is not today" do
      it "renders no relay controls" do
        action.call(date: 1.week.ago.to_date.iso8601)

        expect(page).to have_no_css(toggle)
        expect(page).to have_no_css("#refresh_all_relays")
      end
    end

    context "when no instrument has a real relay" do
      let!(:relay) { create(:relay_dummy, instrument:) }

      it "renders no relay controls" do
        action.call

        expect(page).to have_no_css(toggle)
        expect(page).to have_no_css("#refresh_all_relays")
      end
    end
  end
end
