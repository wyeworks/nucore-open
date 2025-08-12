# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifier do
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { create(:setup_facility) }
  let(:order) { create(:purchased_order, product:) }
  let(:product) { create(:setup_instrument, facility:) }
  let(:user) { order.user }

  if EngineManager.engine_loaded?(:c2po)
    describe ".statement" do
      let(:account) { create(:purchase_order_account, :with_account_owner) }
      let(:statement) { create(:statement, facility:, account:) }
      let(:email_html) { email.html_part.to_s.gsub(/&nbsp;/, " ") } # Markdown changes some whitespace to &nbsp;
      let(:email_text) { email.text_part.to_s }

      let(:action) do
        lambda do
          Notifier.statement(
            user:, facility:, account:, statement:,
          ).deliver_now
        end
      end

      it "generates a statement email", :aggregate_failures do
        action.call

        expect(email.to).to eq [user.email]
        expect(email.subject).to include(I18n.t(".Statement"))
        expect(email_html).to include(statement.account.to_s)
        expect(email_text).to include(statement.account.to_s)

        if Settings.email.invoice_bcc
          expect(email.bcc).to eq [Settings.email.invoice_bcc]
        end
      end

      describe "email log event" do
        context "when ff is off", feature_setting: { billing_log_events: false } do
          it "does not create a log event" do
            expect { action.call }.to_not(
              change { LogEvent.count }
            )
          end
        end

        context "when ff is on", feature_setting: { billing_log_events: true } do
          it "creates a log event" do
            expect { action.call }.to(
              change do
                LogEvent.where(event_type: :statement_email).count
              end.by(1)
            )
          end
        end
      end
    end
  end

  describe ".review_orders" do
    let(:accounts) do
      create_list(:setup_account, 2, owner: user, facility:)
    end
    let(:email_html) { email.html_part.to_s.gsub(/&nbsp;/, " ") } # Markdown changes some whitespace to &nbsp;
    let(:email_text) { email.text_part.to_s }
    let(:action) do
      lambda do
        Notifier.review_orders(
          user:, facility:, accounts:
        ).deliver_now
      end
    end

    it "generates a review_orders notification", :aggregate_failures do
      action.call

      expect(email.to).to eq [user.email]
      expect(email.subject).to include("Orders For Review: #{facility.abbreviation}")

      [email_html, email_text].each do |email_content|
        expect(email_content)
          .to include("/transactions/in_review")
          .and include(accounts.first.description)
          .and include(accounts.last.description)
      end
    end

    describe "log event creation" do
      context "when ff is on", feature_setting: { billing_log_events: false } do
        it "does not create a log event" do
          expect { action.call }.to_not(
            change { LogEvent.count }
          )
        end
      end

      context "when ff is off", feature_setting: { billing_log_events: true } do
        it "creates a log event" do
          expect { action.call }.to(
            change do
              LogEvent.where(event_type: :review_orders_email).count
            end.by(1)
          )
        end

        it "includes metadata fields in the log event" do
          action.call
          
          log_event = LogEvent.where(event_type: :review_orders_email).last
          expect(log_event.metadata["accounts_ids"]).to contain_exactly(accounts.first.id, accounts.last.id)
          expect(log_event.metadata["facility_id"]).to eq(facility.id)
          expect(log_event.metadata["object"]).to include(accounts.first.description)
          expect(log_event.metadata["object"]).to include(accounts.last.description)
          # order_ids will be an array (possibly empty if no orders need notification)
          expect(log_event.metadata["order_ids"]).to be_an(Array)
        end

        context "with no orders needing notification" do
          it "includes empty order_ids array in metadata" do
            action.call
            
            log_event = LogEvent.where(event_type: :review_orders_email).last
            expect(log_event.metadata["order_ids"]).to eq([])
          end
        end
      end
    end
  end

  describe ".user_update" do
    let(:account) do
      create(:setup_account, owner: user, facility:)
    end
    let(:email_html) do
      email.html_part.to_s
           .gsub(/&nbsp;/, " ") # Markdown changes some whitespace to &nbsp;
           .gsub(/&ldquo;/, "\"").gsub(/&rdquo;/, "\"") # Translate quotes
    end
    let(:email_text) { email.text_part.to_s }
    let(:admin_user) { create(:user) }

    before(:each) do
      Notifier.user_update(user:,
                           created_by: admin_user,
                           role: AccountUser::ACCOUNT_PURCHASER,
                           send_to: "john@example.com",
                           account:).deliver_now
    end

    it "generates a user_update notification", :aggregate_failures do
      expect(email.to).to eq ["john@example.com"]
      expect(email.subject).to include("#{user} has been added to your #{I18n.t('app_name')} Payment Source")

      [email_html, email_text].each do |email_content|
        expect(email_content)
          .to include(
            "#{user} has been added to the #{I18n.t('app_name')} Payment Source \"#{account}\" as Purchaser by administrator #{admin_user}",
          )
      end
    end
  end
end
