# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Statements" do
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_item, facility:) }
  let(:order) { create(:setup_order, product:) }
  let(:order_detail) { order.order_details.first }
  let(:statement) { create(:statement, facility:) }

  before do
    statement.add_order_detail(order_detail)
    statement.save!
  end

  describe "index" do
    before { login_as create(:user, :administrator) }

    it "shows statement view link on index" do
      get facility_statements_path(facility)

      expect(page).to(
        have_link("View", href: facility_statement_path(facility, statement))
      )
    end

    describe "resend action", feature_setting: { "notifications.send_statement_emails": true } do
      it "shows it if invoice unreconciled" do
        get facility_statements_path(facility)

        expect(page).to have_link(
          "Resend", href: resend_emails_facility_statement_path(facility, statement),
        )
      end

      context "when statement reconciled" do
        before do
          statement.order_details.update_all(state: :reconciled)
        end

        it "does not show the resend link" do
          get facility_statements_path(facility)

          expect(page).not_to have_link(
            "Resend", href: resend_emails_facility_statement_path(facility, statement),
          )
        end
      end

      context "when statement canceled" do
        before do
          statement.touch(:canceled_at)
        end

        it "does not show the resend link" do
          get facility_statements_path(facility)

          expect(page).not_to have_link(
            "Resend", href: resend_emails_facility_statement_path(facility, statement),
          )
        end
      end

      context "when statement unrecoverable" do
        before { statement.order_details.update_all(state: :unrecoverable) }

        it "does not send emails" do
          get facility_statements_path(facility)

          expect(page).not_to have_link(
            "Resend", href: resend_emails_facility_statement_path(facility, statement),
          )
        end
      end
    end
  end

  describe "resend_emails", feature_setting: { "notifications.send_statement_emails": true } do
    let(:action) do
      -> { post resend_emails_facility_statement_path(facility, statement) }
    end

    before { login_as create(:user, :administrator) }

    context "when statement unreconciled" do
      it "sends emails" do
        expect { action.call }.to have_enqueued_mail(Notifier, :statement)
      end
    end

    context "when reconciled" do
      before { statement.order_details.update_all(state: :reconciled) }

      it "does not send emails" do
        expect { action.call }.not_to have_enqueued_mail
      end
    end

    context "when canceled" do
      before { statement.touch(:canceled_at) }

      it "does not send emails" do
        expect { action.call }.not_to have_enqueued_mail
      end
    end

    context "when unrecoverable" do
      before { statement.order_details.update_all(state: :unrecoverable) }

      it "does not send emails" do
        expect { action.call }.not_to have_enqueued_mail
      end
    end
  end

  describe "show" do
    before { login_as create(:user, :administrator) }

    it "shows statements orders" do
      get facility_statement_path(facility, statement)

      expect(page).to have_content(order_detail.order_number)
    end
  end

  describe "Unreconcile button on show" do
    let(:unreconcile_path) { unreconcile_facility_statement_path(facility, statement) }

    def unreconcile_button
      get facility_statement_path(facility, statement)
      page.has_button?("Unreconcile")
    end

    shared_examples_for "a hidden Unreconcile button" do
      it "does not show the button" do
        expect(unreconcile_button).to be false
      end
    end

    context "when the statement is reconciled", feature_setting: { "billing.allow_mass_unreconciling" => true } do
      before { statement.order_details.update_all(state: :reconciled) }

      context "as a global administrator" do
        before { login_as create(:user, :administrator) }

        it "shows the button" do
          expect(unreconcile_button).to be true
        end

        it "posts to the unreconcile path" do
          get facility_statement_path(facility, statement)

          expect(page).to have_css("form[action='#{unreconcile_path}'][method='post']")
        end

        it "disables the button on submit" do
          get facility_statement_path(facility, statement)

          expect(page).to have_css(
            "form[action='#{unreconcile_path}'] button[type='submit'][data-disable-with]"
          )
        end
      end

      context "as a facility director" do
        before { login_as create(:user, :facility_director, facility:) }

        it_behaves_like "a hidden Unreconcile button"
      end
    end

    context "when the feature is off", feature_setting: { "billing.allow_mass_unreconciling" => false } do
      before do
        statement.order_details.update_all(state: :reconciled)
        login_as create(:user, :administrator)
      end

      it_behaves_like "a hidden Unreconcile button"
    end

    context "when the statement is not reconciled", feature_setting: { "billing.allow_mass_unreconciling" => true } do
      before { login_as create(:user, :administrator) }

      it_behaves_like "a hidden Unreconcile button"
    end

    context "when the statement is canceled", feature_setting: { "billing.allow_mass_unreconciling" => true } do
      before do
        statement.order_details.update_all(state: :reconciled)
        statement.touch(:canceled_at)
        login_as create(:user, :administrator)
      end

      it_behaves_like "a hidden Unreconcile button"
    end
  end

  describe "unreconcile" do
    let(:action) { -> { post unreconcile_facility_statement_path(facility, statement) } }

    before do
      order_detail.update!(actual_cost: 10, actual_subsidy: 0)
      order_detail.update!(
        state: "reconciled",
        order_status: OrderStatus.reconciled,
        reconciled_at: 1.day.ago,
        deposit_number: "TX-1",
        reconciled_note: "Reconciled manually",
      )
    end

    shared_examples_for "an unreconcile that is not permitted" do
      it "denies access" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end

      it "leaves the order detail reconciled" do
        action.call

        order_detail.reload
        expect(order_detail.state).to eq("reconciled")
        expect(order_detail.deposit_number).to eq("TX-1")
        expect(order_detail.reconciled_note).to eq("Reconciled manually")
      end

      it "logs nothing" do
        expect { action.call }.not_to change(LogEvent, :count)
      end
    end

    context "when the feature is off", feature_setting: { "billing.allow_mass_unreconciling" => false } do
      before { login_as create(:user, :administrator) }

      it_behaves_like "an unreconcile that is not permitted"
    end

    context "when the feature is on", feature_setting: { "billing.allow_mass_unreconciling" => true } do
      context "as a facility director" do
        before { login_as create(:user, :facility_director, facility:) }

        it_behaves_like "an unreconcile that is not permitted"
      end

      context "with the billing_journals granular permission",
              feature_setting: { "billing.allow_mass_unreconciling" => true, granular_permissions: true } do
        let(:user) { create(:user) }

        before do
          FacilityUserPermission.create!(
            user:, facility:, read_access: true, billing_journals: true
          )
          login_as user
        end

        it_behaves_like "an unreconcile that is not permitted"
      end

      context "as a global administrator" do
        let(:admin) { create(:user, :administrator) }

        before { login_as admin }

        it "unreconciles the order detail" do
          action.call

          order_detail.reload
          expect(order_detail.state).to eq("complete")
          expect(order_detail.reconciled_at).to be_nil
          expect(order_detail.deposit_number).to be_nil
          expect(order_detail.reconciled_note).to be_nil
        end

        it "leaves the statement unreconciled" do
          action.call

          expect(statement.reload.status).to eq(:unreconciled)
        end

        it "logs the action with the cleared fields" do
          action.call

          log_event = LogEvent.where(loggable: statement, event_type: :unreconciled).last
          expect(log_event.user).to eq(admin)
          expect(log_event.metadata["deposit_numbers"]).to eq(["TX-1"])
          expect(log_event.metadata["reconciled_notes"]).to eq(["Reconciled manually"])
        end

        it "redirects back to the statement with a notice" do
          action.call

          expect(response).to redirect_to(facility_statement_path(facility, statement))
          expect(flash[:notice]).to eq("1 order detail(s) successfully unreconciled")
        end

        context "when nothing on the statement is reconciled" do
          before do
            order_detail.update!(state: "complete", order_status: OrderStatus.complete)
          end

          it "flashes an error and logs nothing" do
            expect { action.call }.not_to change(LogEvent, :count)

            expect(flash[:error]).to eq(
              "No orders on this statement were eligible to unreconcile"
            )
          end
        end
      end
    end
  end
end
