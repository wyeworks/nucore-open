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

    describe "resend action", feature_setting: { send_statement_emails: true } do
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
    end
  end

  describe "resend_emails", feature_setting: { send_statement_emails: true } do
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

  end

  describe "show" do
    before { login_as create(:user, :administrator) }

    it "shows statements orders" do
      get facility_statement_path(facility, statement)

      expect(page).to have_content(order_detail.order_number)
    end
  end
end
