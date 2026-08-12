# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccountsReconciliationController do

  class ReconciliationTestAccount < Account

    extend ReconcilableAccount

  end

  FactoryBot.define do
    factory :reconciliation_test_account, class: ReconciliationTestAccount, parent: :nufs_account do
    end
  end

  before(:all) do
    Account.config.statement_account_types << "ReconciliationTestAccount"
    Nucore::Application.reload_routes!
  end

  after(:all) do
    Account.config.statement_account_types.delete("ReconciliationTestAccount")
    Nucore::Application.reload_routes!
  end

  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:account) { FactoryBot.create(:reconciliation_test_account, :with_account_owner) }
  let(:product) { FactoryBot.create(:setup_item, facility: facility) }
  let(:order) { FactoryBot.create(:purchased_order, product: product, account: account) }
  let(:order_detail) { order.order_details.first }
  let(:statement) do
    FactoryBot.create(:statement, account: account, facility: facility,
                                  created_by_user: admin, created_at: 5.days.ago)
  end
  let(:admin) { FactoryBot.create(:user, :administrator) }

  before do
    order_detail.change_status!(OrderStatus.complete)
    order_detail.update(reviewed_at: 5.minutes.ago, statement: statement)
  end

  describe "update" do
    before { sign_in admin }
    let(:formatted_reconciled_at) { reconciled_at.presence&.to_date&.iso8601 }

    def perform
      post :update, params: { facility_id: facility.url_name, account_type: "ReconciliationTestAccount",
                              reconciled_at: formatted_reconciled_at,
                              order_detail: {
                                order_detail.id.to_s => {
                                  selected: "1",
                                  reconciled_note: "A note",
                                },
                              } }
    end

    describe "when there is an error" do
      let(:reconciled_at) { 1.day.from_now } # This will cause an error
      let(:search_params) { { accounts: [account.id], page: 2 } }
      let(:url_helpers) { Rails.application.routes.url_helpers }

      it "preserves search parameters in the redirect" do
        post :update, params: {
          facility_id: facility.url_name,
          account_type: "ReconciliationTestAccount",
          reconciled_at: formatted_reconciled_at,
          search: search_params,
          page: 2,
          order_detail: {
            order_detail.id.to_s => {
              selected: "1",
              reconciled_note: "A note",
            },
          }
        }

        location = response.redirect_url
        expect(location).to include(
          url_helpers.reconciliation_tests_facility_accounts_path(facility)
        )
        expect(location).to include("search%5Baccounts%5D%5B%5D=#{account.id}")
        expect(location).to include("page=2")
      end
    end

    describe "reconciliation date", :time_travel do
      describe "with a reconciliation date of today" do
        let(:reconciled_at) { Time.current }

        it "updates the reconciled_at" do
          expect { perform }.to change { order_detail.reload.reconciled_at }.to(Time.current.beginning_of_day)
        end
      end

      describe "with a reconciliation date of yesterday" do
        let(:reconciled_at) { 1.day.ago }

        it "updates the reconciled_at" do
          expect { perform }.to change { order_detail.reload.reconciled_at }.to(1.day.ago.beginning_of_day)
        end
      end

      describe "with a reconciliation date after today" do
        let(:reconciled_at) { 1.day.from_now }

        it "does not reconcile the order" do
          expect { perform }.not_to change { order_detail.reload.state }.from("complete")
        end

        it "has a flash message" do
          perform
          expect(flash[:error]).to include("cannot be in the future")
        end
      end

      describe "with a reconciliation date before the statement" do
        let(:reconciled_at) { 10.days.ago }

        it "does not reconcile the order" do
          expect { perform }.not_to change { order_detail.reload.state }.from("complete")
        end

        it "has a flash message" do
          perform
          expect(flash[:error]).to include("must be after all journal or #{I18n.t("statement_downcase")} dates")
        end
      end

      describe "with the reconciliation date on the same day as the statement" do
        let(:reconciled_at) { 5.days.ago - 1.hour }

        it "updates the reconciled_at" do
          expect { perform }.to change { order_detail.reload.reconciled_at }.to(reconciled_at.beginning_of_day)
        end
      end

      describe "invalid reconciliation date" do
        describe "a nil reconciliation date" do
          let(:reconciled_at) { nil }

          it "does not update" do
            expect { perform }.not_to change { order_detail.reload.state }.from("complete")
          end

          it "has an error" do
            perform
            expect(flash[:error]).to include("Reconciliation Date is required")
          end
        end

        describe "a blank reconciliation date" do
          let(:reconciled_at) { "" }

          it "does not update" do
            expect { perform }.not_to change { order_detail.reload.state }.from("complete")
          end

          it "has an error" do
            perform
            expect(flash[:error]).to include("Reconciliation Date is required")
          end
        end

        describe "an invalid date" do
          let(:formatted_reconciled_at) { "something" }

          it "has an error" do
            perform
            expect(flash[:error]).to include("Reconciliation Date is required")
          end
        end
      end
    end

    describe "log event creation" do
      let(:reconciled_at) { Time.current }

      it "creates a log event for the statement" do
        expect { perform }.to change {
          LogEvent.where(loggable: statement, event_type: :closed).count
        }.by(1)
      end

      it "includes reconciled notes in metadata" do
        perform
        log_event = LogEvent.where(loggable: statement, event_type: :closed).last
        expect(log_event.metadata["reconciled_notes"]).to eq(["A note"])
      end

      context "when billing_log_events is disabled", feature_setting: { "billing.billing_log_events" => false } do
        it "still creates the statement closed log event" do
          expect { perform }.to change {
            LogEvent.where(loggable: statement, event_type: :closed).count
          }.by(1)
        end
      end
    end
  end

  describe "two-tier reconciliation", feature_setting: { "billing.two_tier_reconciliation" => true, "billing.show_reconciliation_deposit_number" => true } do
    let(:other_order) { create(:purchased_order, product:, account:) }
    let(:other_order_detail) { other_order.order_details.first }
    let(:order_details) { [order_detail, other_order_detail] }

    before do
      other_order_detail.change_status!(OrderStatus.complete)
      other_order_detail.update(reviewed_at: 5.minutes.ago, statement:)
      sign_in admin
    end

    describe "index" do
      def perform(params = {})
        get :index, params: { facility_id: facility.url_name, account_type: "ReconciliationTestAccount" }.merge(params)
      end

      it "renders the invoice selection page" do
        perform
        expect(response).to render_template(:index_by_statement)
        expect(assigns(:statements)).to include(statement)
      end

      it "renders the individual items page when show_items is set" do
        perform(show_items: true)
        expect(response).to render_template(:index)
      end

      context "when the feature is off", feature_setting: { "billing.two_tier_reconciliation" => false } do
        it "renders the individual items page" do
          perform
          expect(response).to render_template(:index)
        end
      end
    end

    describe "update" do
      def perform(params = {})
        post :update, params: {
          facility_id: facility.url_name,
          account_type: "ReconciliationTestAccount",
          reconciled_at: Date.current.iso8601,
          reconcile_statement: "Reconcile",
          bulk_note_checkbox: "1",
          bulk_note: "A bulk note",
          bulk_deposit_number: "TX-123",
          search: { statements: [statement.id.to_s] },
        }.merge(params)
      end

      it "reconciles every order detail on the invoice" do
        expect { perform }.to change {
          order_details.map { |order_detail| order_detail.reload.state }
        }.to(%w(reconciled reconciled))
      end

      it "applies the note and transaction id to every order detail" do
        perform
        order_details.each(&:reload)
        expect(order_details.map(&:reconciled_note)).to all(eq("A bulk note"))
        expect(order_details.map(&:deposit_number)).to all(eq("TX-123"))
      end

      it "does not reconcile when the transaction id is blank" do
        expect { perform(bulk_deposit_number: "") }.not_to change {
          order_detail.reload.state
        }.from("complete")
        expect(flash[:error]).to include("may not be blank")
      end

      it "does not reconcile when no invoice is selected" do
        expect { perform(search: { statements: [""] }) }.not_to change {
          order_detail.reload.state
        }.from("complete")
        expect(flash[:error]).to include("select an invoice")
      end

      it "redirects to the individual items page with the invoice pre-selected" do
        expect { perform(reconcile_statement: nil, display_items: "Display Individual Items") }.not_to change {
          order_detail.reload.state
        }.from("complete")
        expect(response.location).to include("show_items=true")
        expect(response.location).to include("search%5Bstatements%5D%5B%5D=#{statement.id}")
      end
    end
  end
end
