require "rails_helper"

RSpec.describe KioskReservationsController, type: :controller do
  let(:facility) { create(:facility) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_facility).and_return(facility)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "before_action #check_kiosk_enabled" do
    context "when the kiosk is enabled" do
      before do
        allow(facility).to receive(:kiosk_enabled?).and_return(true)
        allow(SettingsHelper).to receive(:feature_on?).with(:kiosk_view).and_return(true)
      end

      it "allows access to the action" do
        expect { get :index, params: { facility_id: facility.id } }.not_to raise_error
      end
    end

    context "when the kiosk is disabled" do
      before do
        allow(facility).to receive(:kiosk_enabled?).and_return(false)
        allow(SettingsHelper).to receive(:feature_on?).with(:kiosk_view).and_return(false)
      end

      it "raises NUCore::PermissionDenied" do
        expect { get :index, params: { facility_id: facility.id } }.to raise_error(NUCore::PermissionDenied)
      end
    end
  end
end
