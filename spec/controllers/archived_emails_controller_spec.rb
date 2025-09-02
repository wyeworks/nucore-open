# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArchivedEmailsController do
  let(:facility) { create(:setup_facility) }
  let(:statement) { create(:statement, facility:) }
  let(:log_event) { LogEvent.log(statement, :statement_email, nil) }

  before do
    log_event.attach_email("From: test@example.com\r\nTo: user@example.com\r\nSubject: Test\r\n\r\nTest body")
  end

  describe "GET #show" do
    context "authorized user" do
      before { sign_in create(:user, :administrator) }

      it "displays email metadata" do
        get :show, params: { billing_log_event_id: log_event.id }
        expect(assigns(:email_subject)).to eq("Test")
        expect(assigns(:email_to)).to eq("user@example.com")
      end
    end

    context "unauthorized user" do
      before { sign_in create(:user) }

      it "raises access denied" do
        expect do
          get :show, params: { billing_log_event_id: log_event.id }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "no archived email" do
      before { sign_in create(:user, :administrator) }

      it "raises record not found" do
        expect do
          get :show, params: { billing_log_event_id: LogEvent.log(statement, :other, nil).id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET #download" do
    context "authorized user" do
      before { sign_in create(:user, :administrator) }

      it "downloads email file" do
        get :download, params: { billing_log_event_id: log_event.id }
        expect(response.content_type).to eq("message/rfc822")
        expect(response.body).to include("From: test@example.com")
      end
    end
  end
end
