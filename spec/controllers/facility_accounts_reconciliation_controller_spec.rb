# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAccountsReconciliationController do

  class ReconciliationTestAccount < Account

    include ReconcilableAccount

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
    order_detail.update_attributes(reviewed_at: 5.minutes.ago, statement: statement)
  end

  describe "update" do
    include DateHelper

    before { sign_in admin }
    let(:formatted_reconciled_at) { format_usa_date(reconciled_at) }

    def perform
      post :update, params: { facility_id: facility.url_name, account_type: "ReconciliationTestAccount",
                              reconciled_at: formatted_reconciled_at,
                              order_detail: {
                                order_detail.id.to_s => {
                                  reconciled: "1",
                                  reconciled_note: "A note",
                                },
                              } }
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
          expect(flash[:error]).to include("must be after all journal or statement dates")
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
  end

end
