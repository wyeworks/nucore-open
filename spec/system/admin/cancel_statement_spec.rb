# frozen_string_literal: true

require "rails_helper"

RSpec.describe "canceling statements" do
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility:) }
  let(:statement) { create(:statement, account: po_account, facility:) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:po_account) { create(:purchase_order_account, :with_account_owner, facility:) }
  let(:account_owner) { po_account.owner_user }
  let!(:order) do
    create(:complete_order,
      product: item,
      quantity: 3,
      account: po_account
    )
  end
  let(:order_detail) { order.order_details.first }

  before(:each) { order_detail.update(statement: statement) }

  context "as an admin" do
    before do
      login_as director
      visit facility_statements_path(facility)
    end

    context "when an order detail is NOT reconciled" do
      it "cancels a statement" do
        within("tr.statement") do
          click_on "Cancel"
        end
        expect(page).to have_content "#{I18n.t('Statement')} has been canceled"
        expect(page).to have_content "Canceled"
      end

      it "does not allow download or emailing of statement" do
        within("tr.statement") do
          click_on "Cancel"
        end
        expect(page).to_not have_link "Download"
        expect(page).to_not have_content "Resend"
        expect(page).to_not have_link "Cancel"
      end
    end

    context "when an order detail is reconciled" do
      before do
        order_detail.to_reconciled!
        visit facility_statements_path(facility)
      end

      it "does not allow statement to be canceled" do
        expect(page).to have_content "Download"
        expect(page).to have_content "Resend" if SettingsHelper.feature_on?(:send_statement_emails)
        expect(page).to_not have_link "Cancel"
      end
    end

    context "when statement is canceled" do
      let(:statement) { create(:statement, canceled_at: 2.days.ago, facility:) }

      it "does not allow statement to be canceled, downloaded, or resent" do
        expect(page).not_to have_link "Download"
        expect(page).not_to have_content "Resend" if SettingsHelper.feature_on?(:send_statement_emails)
        expect(page).not_to have_link "Cancel"
      end
    end
  end

  context "as an account owner" do
    before do
      login_as account_owner
      visit account_statements_path(po_account)
    end

    it "does not allow statement to be canceled or resent" do
      expect(page).to have_content "Download"
      expect(page).not_to have_content "Resend" if SettingsHelper.feature_on?(:send_statement_emails)
      expect(page).not_to have_link "Cancel"
    end
  end
end
