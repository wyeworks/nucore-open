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
    let(:formatted_reconciled_at) { SpecDateHelper.format_usa_date(reconciled_at) }

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

      context "when billing_log_events is enabled", feature_setting: { billing_log_events: true } do
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
      end

      context "when billing_log_events is disabled", feature_setting: { billing_log_events: false } do
        it "does not create a log event" do
          expect { perform }.not_to change {
            LogEvent.where(loggable: statement, event_type: :closed).count
          }
        end
      end
    end
  end
end
