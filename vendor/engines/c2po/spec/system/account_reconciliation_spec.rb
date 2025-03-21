# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account Reconciliation", js: true do
  include C2poTestHelper

  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:orders) do
    accounts.map { |account| create(:purchased_order, product: item, account: account) }
  end
  let(:statements) do
    accounts.map { |account| create(:statement, account: account, facility: facility, created_by_user: director, created_at: 2.days.ago) }
  end

  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:statement) { StatementPresenter.new order_detail.statement }

  before do
    orders.zip(statements).each do |order, statement|
      order.order_details.each do |od|
        od.to_complete!
        od.update!(statement: statement)
      end
    end

    login_as director
  end

  describe "Credit Cards" do
    let(:accounts) { create_list(:credit_card_account, 2, :with_account_owner) }
    let(:order_detail) { orders.first.order_details.first }
    # This is a page-specific format
    let(:order_number) { "##{orders.first.id} - #{order_detail.id}" }
    let(:other_order_number) { "##{orders.last.id} - #{orders.last.order_details.first.id}" }

    it "can search and then reconcile a credit card order" do
      skip_if_credit_card_unreconcilable

      visit facility_notifications_path(facility)
      click_link "Reconcile Credit Cards"

      expect(page).to have_content(order_number)
      expect(page).to have_content(other_order_number)

      select_from_chosen accounts.first.account_list_item, from: "Payment Sources"
      click_button "Filter"
      expect(page).to have_content(order_number)
      expect(page).not_to have_content(other_order_number)

      visit credit_cards_facility_accounts_path(facility)
      select_from_chosen accounts.first.owner_user.full_name, from: "Owners"
      click_button "Filter"
      expect(page).to have_content(order_number)
      expect(page).not_to have_content(other_order_number)

      visit credit_cards_facility_accounts_path(facility)
      select_from_chosen statements.first.invoice_number, from: I18n.t("Statements")
      click_button "Filter"
      expect(page).to have_content(order_number)
      expect(page).not_to have_content(other_order_number)

      check "order_detail_#{order_detail.id}_reconciled"

      fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
      fill_in "order_detail_#{order_detail.id}_reconciled_note", with: "this is a note!"
      click_button "Update Orders", match: :first

      expect(order_detail.reload).to be_reconciled
      expect(order_detail.reconciled_note).to eq("this is a note!")
      expect(order_detail.reconciled_at).to eq(1.day.ago.beginning_of_day)

      # ensure the closed by times show up on the statement history page
      click_link "#{I18n.t('Statement')} History"
      expect(page).to have_content(statement.closed_by_times)
    end

    context "with bulk reconciliation note" do
      it "sets the note when checkbox is checked" do
        skip_if_credit_card_unreconcilable

        visit credit_cards_facility_accounts_path(facility)
        click_link "Reconcile Credit Cards"

        check "Use Bulk Note"
        expect(page).to have_button("Update Orders", disabled: true)

        fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
        check "order_detail_#{order_detail.id}_reconciled"
        expect(page).to have_button("Update Orders", disabled: false)

        check "order_detail_#{orders.last.order_details.first.id}_reconciled"
        fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
        click_button "Update Orders", match: :first

        expect(order_detail.reload.reconciled_note).to eq("this is the bulk note")
        expect(orders.last.order_details.first.reload.reconciled_note).to eq("this is the bulk note")
      end

      it "does NOT set the note when checkbox is NOT checked" do
        skip_if_credit_card_unreconcilable

        visit credit_cards_facility_accounts_path(facility)
        click_link "Reconcile Credit Cards"

        check "Use Bulk Note"
        fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
        uncheck "Use Bulk Note"
        check "order_detail_#{order_detail.id}_reconciled"
        check "order_detail_#{orders.last.order_details.first.id}_reconciled"
        fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
        click_button "Update Orders", match: :first

        expect(order_detail.reload.reconciled_note).to eq("")
        expect(orders.last.order_details.first.reload.reconciled_note).to eq("")
      end
    end
  end

  describe "Purchase Orders" do
    let(:accounts) { create_list(:purchase_order_account, 2, :with_account_owner) }
    let(:order_detail) { orders.first.order_details.first }
    # This is a page-specific format
    let(:order_number) { "##{orders.first.id} - #{orders.first.order_details.first.id}" }
    let(:other_order_number) { "##{orders.last.id} - #{orders.last.order_details.first.id}" }

    it "can search and then reconcile a PO order" do
      visit facility_notifications_path(facility)
      click_link "Reconcile Purchase Orders"

      expect(page).to have_content(order_number)
      expect(page).to have_content(other_order_number)

      select_from_chosen accounts.first.account_list_item, from: "Payment Sources"
      click_button "Filter"
      expect(page).to have_content(order_number)
      expect(page).not_to have_content(other_order_number)

      check "order_detail_#{order_detail.id}_reconciled"
      fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
      fill_in "order_detail_#{order_detail.id}_reconciled_note", with: "this is a note!"
      click_button "Update Orders", match: :first

      expect(order_detail.reload).to be_reconciled
      expect(order_detail.reconciled_note).to eq("this is a note!")
      expect(order_detail.reconciled_at).to eq(1.day.ago.beginning_of_day)

      # ensure the closed by times show up on the statement history page
      click_link "#{I18n.t('Statement')} History"
      expect(page).to have_content(statement.closed_by_times)
    end

    it "can take a bulk reconciliation note" do
      visit facility_notifications_path(facility)
      click_link "Reconcile Purchase Orders"

      check "Use Bulk Note"
      fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
      check "order_detail_#{order_detail.id}_reconciled"
      check "order_detail_#{orders.last.order_details.first.id}_reconciled"
      fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
      click_button "Update Orders", match: :first
      expect(order_detail.reload.reconciled_note).to eq("this is the bulk note")
      expect(orders.last.order_details.first.reload.reconciled_note).to eq("this is the bulk note")
    end
  end
end
