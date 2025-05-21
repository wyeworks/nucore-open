# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "log_events", type: :request do
  describe "index" do
    let(:some_user) { create(:user, first_name: "Socrates") }
    let(:facility) { create(:setup_facility) }
    let(:product) { create(:setup_service, facility:) }
    let(:order) { create(:setup_order, product:) }
    let(:order_detail) { order.order_details.first }
    let(:admin) { create(:user, :administrator) }

    before do
      [
        [order_detail, "dispute"],
        [order_detail, "resolve"],

      ].each do |loggable, event_type|
        LogEvent.log(loggable, event_type, admin)
      end
    end

    it "requires login" do
      get log_events_path

      expect(response.location).to eq(new_user_session_url)
    end

    context "as admin" do
      before { login_as admin }

      it "returns ok" do
        get log_events_path

        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Event Log")
      end

      it "renders events" do
        get log_events_path

        expect(page).to have_content(facility.name)
        expect(page).to have_content(admin.name)
        expect(page).to have_content(order_detail.order_number)
      end

      context "when csv email report is requested" do
        let(:action) { -> { get log_events_path(format: :csv) } }
        let(:report_class) { Reports::LogEventsReport }

        include_examples "csv email action"
      end
    end

    context "email events" do
      before do
        LogEvent.destroy_all
        LogEvent.log(some_user, :review_orders_email, nil)

        login_as admin
      end

      it "does not render email events" do
        get log_events_path

        expect(page).to_not have_content(some_user.first_name)
      end
    end
  end
end
