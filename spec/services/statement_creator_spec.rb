# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementCreator do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:account) do
    FactoryBot.create(
      :nufs_account,
      account_users_attributes: [FactoryBot.attributes_for(:account_user, user: user)],
      type: Account.config.statement_account_types.first,
    )
  end
  let(:order_detail_1) { place_and_complete_item_order(user, facility, account, true) }
  let(:order_detail_2) { place_and_complete_item_order(user, facility, account, true) }
  let(:order_detail_3) { place_and_complete_item_order(user, facility, account, false) }
  let(:creator) { described_class.new(order_detail_ids: [order_detail_1.id, order_detail_2.id], session_user: user, current_facility: facility) }

  describe "#new" do
    it "sets variables" do
      expect(creator.order_detail_ids).to match_array([order_detail_1.id, order_detail_2.id])
      expect(creator.session_user).to eq(user)
      expect(creator.current_facility).to eq(facility)
    end

    context "with parent invoice number" do
      let(:creator_with_parent) { described_class.new(order_detail_ids: [order_detail_1.id], session_user: user, current_facility: facility, parent_invoice_number: "123-456") }

      it "sets parent_invoice_number" do
        expect(creator_with_parent.parent_invoice_number).to eq("123-456")
      end
    end
  end

  describe "#create" do
    context "when there are no errors" do
      before { creator.create }

      it "sets order details to be statemented" do
        expect(creator.to_statement).not_to be_empty
        expect(creator.to_statement.keys.first.id).to eq(account.id)
      end

      it "creates statements" do
        expect(Statement.all.length).to eq(1)
        expect(order_detail_1.reload.statement).not_to be_nil
        expect(order_detail_2.reload.statement).not_to be_nil
        log_event = LogEvent.find_by(loggable: order_detail_1.statement, event_type: :create)
        expect(log_event).to be_present
      end
    end

    context "when there are errors" do
      before do
        creator.errors << "There is an error"
      end

      it "does not create statements" do
        expect { creator.create }.not_to change(Statement.all, :count)
      end
    end

    context "with parent statement functionality" do
      let(:parent_statement) { create(:statement, account:, facility:, created_by: user.id) }
      let(:parent_invoice_number) { parent_statement.invoice_number }
      let(:creator_with_parent) do
        described_class.new(
          order_detail_ids: [order_detail_1.id],
          session_user: user,
          current_facility: facility,
          parent_invoice_number:,
        )
      end

      context "when reference_statement_invoice_number feature is on", feature_setting: { reference_statement_invoice_number: true } do
        it "creates statement with parent_statement_id" do
          creator_with_parent.create
          expect(creator_with_parent.errors).to be_empty

          # Just Statement.last was not reliable. It returned the parent statement instead of the child statement.
          statement = Statement.order(invoice_number: :asc).last
          expect(statement.parent_statement_id).to eq(parent_statement.id)
          expect(statement.invoice_number).to eq("#{parent_statement.invoice_number}-2")
        end

        context "with invalid invoice number format" do
          let(:invalid_invoice_number) { "invalid-format" }
          let(:creator_with_invalid) do
            described_class.new(
              order_detail_ids: [order_detail_1.id],
              session_user: user,
              current_facility: facility,
              parent_invoice_number: invalid_invoice_number,
            )
          end

          it "adds error for invalid format" do
            creator_with_invalid.create
            expect(creator_with_invalid.errors).to include(I18n.t("services.statement_creator.invalid_invoice_format"))
          end
        end

        context "with non-existent parent statement" do
          let(:non_existent_invoice) { "999-999" }
          let(:creator_with_nonexistent) do
            described_class.new(
              order_detail_ids: [order_detail_1.id],
              session_user: user,
              current_facility: facility,
              parent_invoice_number: non_existent_invoice,
            )
          end

          it "adds error for non-existent parent statement" do
            creator_with_nonexistent.create
            expect(creator_with_nonexistent.errors).to include(
              I18n.t("services.statement_creator.parent_statement_not_found", invoice_number: non_existent_invoice)
            )
          end
        end
      end

      context "when reference_statement_invoice_number feature is off", feature_setting: { reference_statement_invoice_number: false } do
        it "ignores parent invoice number and creates standard statement" do
          creator_with_parent.create
          expect(creator_with_parent.errors).to be_empty

          statement = Statement.last
          expect(statement.parent_statement_id).to be_nil
          expect(statement.invoice_number).to eq(statement.build_invoice_number)
        end
      end
    end
  end

  describe "#formatted_errors" do
    before { creator.errors = ["Error message", "Another error message"] }

    it "formats the errors with line breaks" do
      expect(creator.formatted_errors).to eq("Error message<br/>Another error message")
    end
  end

  describe "#send_statement_emails" do
    before { creator.create }

    context "when statement emailing is on", feature_setting: { send_statement_emails: true } do
      it "sends statements" do
        expect { creator.send_statement_emails }.to enqueue_mail(Notifier, :statement)
      end
    end

    context "when statement emailing is off", feature_setting: { send_statement_emails: false } do
      it "does not send statements" do
        expect { creator.send_statement_emails }.not_to enqueue_mail
      end
    end
  end

  describe "#account_list" do
    before { creator.create }

    it "returns account list items for accounts statemented" do
      expect(creator.account_list).to match_array([account.account_list_item])
    end
  end

  describe "#formatted_account_list" do
    before do
      creator.account_statements = {}
      creator.account_statements[account] = "Statement"
    end

    it "returns account list items with line breaks" do
      expect(creator.formatted_account_list).to eq(account.account_list_item)
    end
  end

end
