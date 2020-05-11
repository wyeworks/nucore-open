# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRoomsApi::EventsController do
  before do
    name = Rails.application.secrets.secure_rooms_api[:basic_auth_name]
    password = Rails.application.secrets.secure_rooms_api[:basic_auth_password]
    encoded_auth_credentials = ActionController::HttpAuthentication::Basic.encode_credentials(name, password)
    request.env["HTTP_AUTHORIZATION"] = encoded_auth_credentials
  end

  describe "create" do
    context "with some data" do
      let(:params) do
        {
          message_id: "000009",
          message_type: "10",
          message_time: "03:25:26 GMT 01/22/2000",
          class_code: "5",
          task_code: "5",
          event_code: "1",
          priority: "100",
          task_description: "eventlogger task",
          event_description: "start task",
        }
      end

      before do
        post :create, params: params
      end

      describe "response" do
        subject { response }

        it { is_expected.to be_successful }
      end

      describe "new alarm_event" do
        subject(:alarm_event) { SecureRooms::AlarmEvent.find_by(message_id: params[:message_id]) }

        it "stores a parsed timestamp properly" do
          m_t = DateTime.strptime(params[:message_time], "%H:%M:%S %Z %m/%d/%Y")
          expect(alarm_event.message_time).to eq m_t
        end

        it "stores the raw post request data" do
          expect(alarm_event.raw_post).to eq request.raw_post
        end

        it "stores all values" do
          expect(alarm_event.message_id).to eq params[:message_id]
          expect(alarm_event.message_type).to eq params[:message_type]
          expect(alarm_event.class_code).to eq params[:class_code]
          expect(alarm_event.task_code).to eq params[:task_code]
          expect(alarm_event.event_code).to eq params[:event_code]
          expect(alarm_event.priority).to eq params[:priority]
          expect(alarm_event.task_description).to eq params[:task_description]
          expect(alarm_event.event_description).to eq params[:event_description]
        end
      end
    end

    context "with invalid credentials" do
      before do
        request.env.delete("HTTP_AUTHORIZATION")
        post :create
      end

      describe "response" do
        subject { response }

        it { is_expected.to have_http_status(:unauthorized) }
      end
    end
  end
end
