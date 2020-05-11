# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailsController do
  let(:facility) { order.facility }
  let(:order) { order_detail.order }
  let(:order_detail) { reservation.order_detail }
  let(:reservation) { create(:purchased_reservation) }
  let(:account) { order_detail.account }
  let(:price_policy) { product.price_policies.first }
  let(:product) { order_detail.product }
  let(:user) { order_detail.user }

  describe "#dispute" do
    let(:params) { { order_id: order.id, id: order_detail.id } }
    before { sign_in user }

    context "when the order is not disputable" do
      before { put :dispute, params: params }

      it { expect(response.code).to eq("404") }
    end

    context "when the order is disputable" do
      before(:each) do
        order_detail.update_attributes!(state: "complete", reviewed_at: 7.days.from_now)
        put :dispute, params: params.merge(order_detail: { dispute_reason: dispute_reason })
      end

      context "with a blank dispute_reason" do
        let(:dispute_reason) { "" }

        it "does not set the dispute at" do
          expect(order_detail.reload.dispute_at).to be_blank
        end
      end

      context "with a dispute_reason" do
        let(:dispute_reason) { "Too expensive" }

        it "captures the dispute at time" do
          expect(order_detail.reload.dispute_at).to be_present
        end

        it "captures who disputed it" do
          expect(order_detail.reload.dispute_by).to eq(user)
        end

        it "logs the dispute" do
          log_event = LogEvent.find_by(loggable: order_detail, event_type: :dispute)
          expect(log_event).to be_present
        end
      end
    end
  end

  describe "#show" do
    def perform
      get :show, params: { order_id: order.id, id: order_detail.id }
    end

    before(:each) do
      sign_in user
    end

    context "when logged in as the user who owns the order" do
      it "can access the page" do
        perform
        expect(response).to access_the_page
      end
    end

    context "when logged in as a user that does not own the order" do
      let(:user) { create(:user) }

      it "cannot access the page" do
        perform
        expect(response.code).to eq("403")
      end
    end

    describe "dispute box" do
      render_views
      before do
        order_detail.update_attributes!(state: "complete", reviewed_at: 7.days.from_now)
      end

      describe "as the owner" do
        let(:user) { order_detail.account.owner_user }

        it "sees the dispute box" do
          perform
          expect(response.body).to include("Dispute")
        end
      end

      describe "as a BA" do
        let!(:account_user) { FactoryBot.create(:account_user, :business_administrator, account: order_detail.account, user: user) }
        let(:user) { FactoryBot.create(:user) }

        it "sees the dispute box" do
          perform
          expect(response.body).to include("Dispute")
        end
      end

      describe "as an account purchaser" do
        let!(:account_user) { FactoryBot.create(:account_user, :purchaser, account: order_detail.account, user: user) }
        let(:user) { FactoryBot.create(:user) }

        it "does not see the dispute box" do
          perform
          expect(response.body).not_to include("Dispute")
        end
      end
    end
  end

  describe "#cancel" do
    context "when the order is a reservation" do
      context "when attempting to cancel the reservation" do
        before { sign_in user }

        context "and the reservation is cancelable" do
          before(:each) do
            expect(reservation).to be_can_cancel
            put :cancel, params: { order_id: order.id, id: order_detail.id }
          end

          it { expect(order_detail.reload).to be_canceled }
        end

        context "and the cancellation notification recipients is set" do
          before { reservation.product.update(cancellation_email_recipients: "cancel@example.com") }

          it "triggers an email" do
            expect { put :cancel, params: { order_id: order.id, id: order_detail.id } }.to change(ActionMailer::Base.deliveries, :count).by(1)
          end
        end

        context "and I am an administrator on the account, but do not own the order" do
          let(:user) { FactoryBot.create(:user) }
          before do
            FactoryBot.create(:account_user, :business_administrator, account: account, user: user)
            put :cancel, params: { order_id: order.id, id: order_detail.id }
          end

          it { expect(order_detail.reload).not_to be_canceled }
          it { expect(response.code).to eq("403") }
        end

        context "and I am just a purchaser on the account" do
          before do
            account.account_users.update_all(user_role: AccountUser::ACCOUNT_PURCHASER)
            put :cancel, params: { order_id: order.id, id: order_detail.id }
          end

          it "cancels the order", :aggregate_failures do
            expect(response).to redirect_to(reservations_path)
            expect(order_detail.reload).to be_canceled
          end
        end

        context "and the reservation is not cancelable" do
          before do
            reservation.update_attributes(actual_start_at: Time.current)
            put :cancel, params: { order_id: order.id, id: order_detail.id }
          end

          it { expect(order_detail.reload).not_to be_canceled }
          it { expect(response.code).to eq("404") }
        end
      end
    end
  end

  describe "edit/update" do
    shared_examples_for "allows the proper users" do
      describe "as the account owner" do
        let(:signed_in_user) { order_detail.account.owner_user }
        before { perform }

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as a business admin" do
        let(:signed_in_user) { FactoryBot.create(:user) }
        before do
          FactoryBot.create(:account_user, :business_administrator,
                            user: signed_in_user, account: order_detail.account)
          perform
        end

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as an account purchaser" do
        let(:signed_in_user) { FactoryBot.create(:user) }
        before do
          FactoryBot.create(:account_user, :purchaser,
                            user: signed_in_user, account: order_detail.account)
          perform
        end

        it "does not load" do
          expect(response.code).to eq("403")
        end
      end

      describe "as the purchaser" do
        let(:signed_in_user) { FactoryBot.create(:user) }
        before do
          FactoryBot.create(:account_user, :purchaser,
                            user: signed_in_user, account: order_detail.account)
          order.update_attributes(user: signed_in_user)
          perform
        end

        it "succeeds" do
          expect(response).to access_the_page
        end
      end

      describe "as a random user" do
        let(:signed_in_user) { FactoryBot.create(:user) }
        before { perform }

        it "does not load" do
          expect(response.code).to eq("403")
        end
      end
    end

    describe "#edit" do
      def perform
        sign_in signed_in_user
        get :edit, params: { order_id: order.id, id: order_detail.id }
      end

      it_behaves_like "allows the proper users"
    end

    describe "#update permissions" do
      # need some params to satisfy strong params
      let(:params) { { field: "dummy" } }

      def perform
        sign_in signed_in_user
        put :update, params: { order_id: order.id, id: order_detail.id, order_detail: params }
      end

      it_behaves_like "allows the proper users"

      describe "does not update other fields" do
        let(:signed_in_user) { user }
        let(:params) { { actual_cost: 113, product_id: 999, user_id: 111, dispute_reason: "Dispute" } }

        it "is successful, but does not change any fields" do
          expect { perform }.not_to change { order_detail.reload.attributes }
          expect(response).to be_redirect
        end
      end
    end

    describe "#show/edit/update based on state" do
      let(:signed_in_user) { user }
      let(:account2) { FactoryBot.create(:setup_account, owner: user) }
      let(:params) { { account_id: account2.id } }

      def perform_show
        sign_in signed_in_user
        get :show, params: { order_id: order.id, id: order_detail.id, order_detail: params }
      end

      def perform_edit
        sign_in signed_in_user
        get :edit, params: { order_id: order.id, id: order_detail.id, order_detail: params }
      end

      def perform_update
        sign_in signed_in_user
        put :update, params: { order_id: order.id, id: order_detail.id, order_detail: params }
      end

      shared_examples_for "can modify the account" do
        describe "on #show" do
          render_views
          it "has the change link on #show" do
            perform_show
            expect(response.body).to include("Change")
          end
        end

        it "has access to the edit page" do
          perform_edit
          expect(response).to be_successful
        end

        it "can update the account" do
          expect { perform_update }.to change { order_detail.reload.account }.to(account2)
        end
      end

      shared_examples_for "cannot modify the account" do
        describe "on #show" do
          render_views
          it "does not have the change link on #show" do
            perform_show
            expect(response.body).not_to include("Change")
          end
        end

        it "does not have access to the edit page" do
          perform_edit
          expect(response).to be_redirect
        end

        it "does not update the account" do
          expect { perform_update }.not_to change { order_detail.reload.account }
        end
      end

      describe "before completion" do
        it_behaves_like "can modify the account"
      end

      describe "after completion" do
        let(:reservation) { FactoryBot.create(:completed_reservation) }

        describe "while in the review period" do
          before { order_detail.update_attributes!(reviewed_at: 7.days.from_now) }
          it_behaves_like "can modify the account"
        end

        describe "when the review period is over" do
          before { order_detail.update_attributes!(reviewed_at: 1.day.ago) }
          it_behaves_like "can modify the account"
        end

        describe "when the review period is over, but it is being disputed" do
          before { order_detail.update_attributes!(reviewed_at: 1.day.ago, dispute_at: 2.days.ago, dispute_reason: "reason") }
          it_behaves_like "can modify the account"
        end

        describe "when the dispute has been resolved" do
          before { order_detail.update_attributes!(reviewed_at: 1.day.ago, dispute_at: 2.days.ago, dispute_resolved_at: Time.current, dispute_reason: "reason", dispute_resolved_reason: "notes") }
          it_behaves_like "can modify the account"
        end

        describe "when the order is statemented" do
          before do
            statement = create(
              :statement, account: account, facility: facility, created_by: user.id)
            order_detail.update_attributes!(
              reviewed_at: 1.day.ago, statement: statement)
          end
          it_behaves_like "cannot modify the account"
        end

        describe "when the order is journaled" do
          before do
            journal = create(:journal)
            order_detail.update_attributes!(
              reviewed_at: 1.day.ago, journal: journal)
          end
          it_behaves_like "cannot modify the account"
        end
      end

      describe "a canceled reservation" do
        before do
          order_detail.update_order_status!(user, OrderStatus.canceled)
        end
        it_behaves_like "cannot modify the account"
      end
    end
  end
end
