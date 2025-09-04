# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "facility_billing_log_events", type: :request do
  let(:some_user) { create(:user, first_name: "Socrates") }
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_service, facility:) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:global_billing_admin) { create(:user, :global_billing_administrator) }
  let(:statement) { create(:statement, order_details: [order_detail]) }

  describe "index" do
    let(:email) do
      double(
        "Email",
        to: "random@example.com",
        subject: "Some Subject"
      )
    end

    def get_index
      get facility_billing_log_events_path(Facility.cross_facility)
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
      get_index

      expect(response.location).to eq new_user_session_url
    end

    describe "as admin" do
      before { login_as global_billing_admin }

      it "returns ok" do
        get_index

        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Billing Log")
      end

      it "renders email events" do
        get_index

        expect(page).to have_content(email.to)
        expect(page).to have_content(email.subject)
        expect(page).to have_content(statement.to_log_s)
        expect(page).to have_content(some_user.first_name)
      end
    end

    describe "filtering" do
      include_context "billing statements with deposit numbers"

      def get_index_with_params(params = {})
        get facility_billing_log_events_path(Facility.cross_facility), params: params
      end

      before do
        LogEvent.log_email(statement1, :statement_email, email)
        LogEvent.log_email(statement2, :statement_email, email)
        login_as global_billing_admin
      end

      it "filters by invoice_number" do
        get_index_with_params(invoice_number: statement1.invoice_number)

        expect(page).to have_content(statement1.to_log_s)
        expect(page).not_to have_content(statement2.to_log_s)
      end

      it "filters by payment_source in account number" do
        get_index_with_params(payment_source: "CHECK")

        expect(page).to have_content(statement1.to_log_s)
        expect(page).not_to have_content(statement2.to_log_s)
      end

      it "filters by payment_source with partial match in account description" do
        get_index_with_params(payment_source: "Chemistry")

        expect(page).to have_content(statement2.to_log_s)
        expect(page).not_to have_content(statement1.to_log_s)
      end

      it "filters case-insensitively by payment_source" do
        get_index_with_params(payment_source: "CHECK")

        expect(page).to have_content(statement1.to_log_s)
        expect(page).not_to have_content(statement2.to_log_s)
      end

      it "displays payment source column with account info" do
        get_index

        expect(page).to have_content("#{account1.account_number} - #{account1.description}")
        expect(page).to have_content("#{account2.account_number} - #{account2.description}")
      end
    end
  end

end
