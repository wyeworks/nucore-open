# frozen_string_literal: true

require "rails_helper"

RSpec.describe RelaysActivationsController do
  let(:instrument) { FactoryBot.create(:setup_instrument) }
  let(:user) { FactoryBot.create(:user, :facility_director, facility: instrument.facility) }
  let(:relay) { build_stubbed(:relay) }

  before do
    allow_any_instance_of(Instrument).to receive(:has_real_relay?).and_return true
    allow_any_instance_of(Instrument).to receive(:relay).and_return relay
    allow(relay).to receive(:activate)
    allow(relay).to receive(:deactivate)
    sign_in user
  end

  describe "POST to #create" do
    it "activates all real relays for the facility’s instruments" do
      expect(relay).to receive(:activate)
      post :create, params: { facility_id: instrument.facility.url_name }
      log_event = LogEvent.find_by(loggable: instrument.facility , event_type: :activate)
      expect(log_event).to be_present
    end

    it "redirects back to the instruments page" do
      post :create, params: { facility_id: instrument.facility.url_name }
      expect(response).to redirect_to facility_instruments_path(instrument.facility)
    end

    it "sets a notice in the flash" do
      post :create, params: { facility_id: instrument.facility.url_name }
      expect(flash[:notice]).to be_present
    end

    it "sets an alert in the flash when an error is encountered" do
      allow(relay).to receive(:activate).and_raise(NetBooter::Error)
      post :create, params: { facility_id: instrument.facility.url_name }
      expect(flash[:alert]).to be_present
    end
  end

  context "DELETE to :destroy" do
    it "deactivates all real relays for the facility’s instruments" do
      expect(relay).to receive(:deactivate)
      delete :destroy, params: { facility_id: instrument.facility.url_name }
      log_event = LogEvent.find_by(loggable: instrument.facility , event_type: :deactivate)
      expect(log_event).to be_present
    end

    it "redirects back to the instruments page" do
      delete :destroy, params: { facility_id: instrument.facility.url_name }
      expect(response).to redirect_to facility_instruments_path(instrument.facility)
    end

    it "sets a notice in the flash" do
      delete :destroy, params: { facility_id: instrument.facility.url_name }
      expect(flash[:notice]).to be_present
    end

    it "sets an alert in the flash when an error is encountered" do
      allow(relay).to receive(:deactivate).and_raise(NetBooter::Error)
      delete :destroy, params: { facility_id: instrument.facility.url_name }
      expect(flash[:alert]).to be_present
    end
  end
end
