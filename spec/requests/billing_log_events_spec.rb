# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "billing_log_events", type: :request do
  let(:some_user) { create(:user, first_name: "Socrates") }
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_service, facility:) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:admin) { create(:user, :administrator) }
  let(:statement) { create(:statement, order_details: [order_detail]) }

  describe "index" do
    let(:email) do
      double(
        "Email",
        to: "random@example.com",
        subject: "Some Subject"
      )
    end

    before do
      [
        [some_user, :review_orders_email],
        [statement, :statement_email],
      ].each do |loggable, event_type|
        LogEvent.log_email(
          loggable,
          event_type,
          email
        )
      end
    end

    it "requires login" do
      get billing_log_events_url

      expect(response.location).to eq new_user_session_url
    end

    describe "as admin" do
      before { login_as admin }

      it "returns ok" do
        get billing_log_events_url

        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Billing Log")
      end

      it "renders email events" do
        get billing_log_events_url

        expect(page).to have_content(email.to)
        expect(page).to have_content(email.subject)
        expect(page).to have_content(statement.to_log_s)
        expect(page).to have_content(some_user.first_name)
      end

      it "displays payment source for statement events" do
        get billing_log_events_url

        expect(page).to have_content("Payment Source")
        expect(page).to have_content("#{statement.account.account_number} - #{statement.account.description}")
      end
    end
  end

end
