# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Voucher Account Reconciliation" do
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:orders) do
    accounts.map { |account| create(:purchased_order, product: item, account: account) }
  end
  let(:statements) do
    accounts.map { |account| create(:statement, account: account, facility: facility, created_by_user: director, created_at: 2.days.ago) }
  end
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:mivp) { UmassCorum::VoucherOrderStatus.mivp }
  let(:accounts) { create_list(:voucher_split_account, 2) }
  let(:order_detail) { orders.first.order_details.first }
  # This is a page-specific format
  let(:order_number) { "##{orders.first.id} - #{order_detail.id}" }
  let(:other_order_number) { "##{orders.second.id} - #{orders.second.order_details.first.id}" }

  before do
    orders.zip(statements).each do |order, statement|
      order.order_details.each do |od|
        od.change_status!(OrderStatus.complete)
        od.update!(statement: statement)
      end
    end

    login_as director
  end

  describe "Voucher Split Accounts" do
    context "Mark MIVP Pending page" do
      before do
        visit facility_notifications_path(facility)
        click_link "Mark MIVP Pending"
      end

      it "can search and then mark a voucher order MIVP Pending" do
        expect(page).to have_content(order_number)
        expect(page).to have_content(other_order_number)
        expect(page).to have_content("Reconciliation Note")
        expect(page).to have_content("Primary")
        expect(page).to have_content("MIVP")

        select accounts.first.account_list_item, from: "Payment Sources"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        select accounts.first.owner_user.full_name, from: "Owners"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        select statements.first.invoice_number, from: "Statements"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        check "order_detail_#{order_detail.id}_mivp_pending"
        click_button "Mark Orders 'MIVP Pending'", match: :first

        expect(order_detail.reload).not_to be_reconciled
        expect(order_detail.reload.order_status).to eq(mivp)
      end

      describe "with bulk reconciliation note" do
        it "sets the note when checkbox is checked" do
          check "Use Bulk Note"
          fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
          check "order_detail_#{order_detail.id}_mivp_pending"
          check "order_detail_#{orders.last.order_details.first.id}_mivp_pending"
          click_button "Mark Orders 'MIVP Pending'", match: :first

          expect(order_detail.reload.reconciled_note).to eq("this is the bulk note")
          expect(orders.last.order_details.first.reload.reconciled_note).to eq("this is the bulk note")
        end

        it "does NOT set the note when checkbox is NOT checked" do
          check "Use Bulk Note"
          fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
          uncheck "Use Bulk Note"
          check "order_detail_#{order_detail.id}_mivp_pending"
          check "order_detail_#{orders.last.order_details.first.id}_mivp_pending"
          click_button "Mark Orders 'MIVP Pending'", match: :first

          expect(order_detail.reload.reconciled_note).to eq("")
          expect(orders.last.order_details.first.reload.reconciled_note).to eq("")
        end
      end

    end

    context "Reconcile Voucher Split Accounts page" do
      before do
        orders.each do |order|
          order.order_details.each do |od|
            od.change_status!(mivp)
          end
        end

        visit facility_notifications_path(facility)
        click_link "Reconcile Voucher Split Accounts"
      end

      it "can search and then reconcile a voucher order" do
        expect(page).to have_content(order_number)
        expect(page).to have_content(other_order_number)

        select accounts.first.account_list_item, from: "Payment Sources"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        select accounts.first.owner_user.full_name, from: "Owners"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        select statements.first.invoice_number, from: "Statements"
        click_button "Filter"
        expect(page).to have_content(order_number)
        expect(page).not_to have_content(other_order_number)

        check "order_detail_#{order_detail.id}_reconciled"
        fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
        click_button "Update Orders", match: :first

        expect(order_detail.reload).to be_reconciled
        expect(order_detail.reload.order_status).not_to eq(mivp)
      end

      describe "with bulk reconciliation note" do
        it "sets the note when checkbox is checked" do
          check "Use Bulk Note"
          fill_in "Bulk Reconciliation Note", with: "this is the bulk note"
          check "order_detail_#{order_detail.id}_reconciled"
          check "order_detail_#{orders.last.order_details.first.id}_reconciled"
          fill_in "Reconciliation Date", with: I18n.l(1.day.ago.to_date, format: :usa)
          click_button "Update Orders", match: :first

          expect(order_detail.reload.reconciled_note).to eq("this is the bulk note")
          expect(orders.last.order_details.first.reload.reconciled_note).to eq("this is the bulk note")
        end

        it "does NOT set the note when checkbox is NOT checked" do
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
  end
end
