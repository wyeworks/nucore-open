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

    context "statement unreconciled events" do
      let(:statement) { create(:statement, facility:) }
      let(:deposit_number_label) { OrderDetail.human_attribute_name(:deposit_number) }
      let(:reconciled_note_label) { OrderDetail.human_attribute_name(:reconciled_note) }
      let(:csv) do
        Reports::LogEventsReport.new(
          start_date: nil, end_date: nil, events: ["statement.unreconciled"], query: nil
        ).to_csv
      end

      before do
        LogEvent.destroy_all
        LogEvent.log(
          statement, :unreconciled, admin,
          metadata: { deposit_numbers: ["TX-1", "TX-2"], reconciled_notes: ["Paid late"] }
        )

        login_as admin
      end

      it "renders the event" do
        get log_events_path

        expect(page).to have_content("#{I18n.t('Statement')} unreconciled")
        expect(page).to have_content(statement.invoice_number)
      end

      it "renders the Transaction IDs and Reconciliation Notes that were cleared" do
        get log_events_path

        expect(page).to have_content("#{deposit_number_label}: TX-1, TX-2", normalize_ws: true)
        expect(page).to have_content("#{reconciled_note_label}: Paid late", normalize_ws: true)
      end

      it "exports the cleared fields" do
        expect(csv).to include(statement.invoice_number)
        expect(csv).to include("#{deposit_number_label}: TX-1, TX-2")
        expect(csv).to include("#{reconciled_note_label}: Paid late")
      end

      context "when the event has no metadata" do
        before do
          LogEvent.destroy_all
          LogEvent.log(statement, :unreconciled, admin)
        end

        it "still renders the row" do
          get log_events_path

          expect(page).to have_content("#{I18n.t('Statement')} unreconciled")
          expect(page).not_to have_content("#{deposit_number_label}:")
        end

        it "exports the object column without a trailing separator" do
          expect(csv).to include(",#{statement.to_log_s},")
        end
      end
    end
  end
end
