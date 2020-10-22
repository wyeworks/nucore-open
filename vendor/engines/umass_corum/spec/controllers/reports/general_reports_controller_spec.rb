# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::GeneralReportsController do
  let(:facility) { item.facility }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:primary_account_1) { FactoryBot.create(:purchase_order_account, :with_account_owner) }
  let(:primary_account_2) { FactoryBot.create(:credit_card_account, :with_account_owner) }
  let(:voucher_split_1) { FactoryBot.create(:voucher_split_account, primary_subaccount: primary_account_1) }
  let(:voucher_split_2) { FactoryBot.create(:voucher_split_account, primary_subaccount: primary_account_2) }
  let!(:order1) { FactoryBot.create(:purchased_order, product: item, account: voucher_split_1) }
  let!(:order2) { FactoryBot.create(:purchased_order, product: item, account: voucher_split_2) }
  let(:administrator) { FactoryBot.create(:user, :administrator) }

  describe "the account report" do
    before do
      sign_in administrator
      get :index, params: { report_by: :account, date_start: 2.months.ago, date_end: Time.current,
                            status_filter: [OrderStatus.new_status], facility_id: facility.url_name,
                            date_range_field: "ordered_at" }, xhr: true
    end

    describe "the MIVP row" do
      let(:row) { assigns[:rows].first }

      it "has the proper data" do
        expect(row.length).to eq(4)
        expect(row.first.to_s).to eq("MIVP Voucher Account / MIVP")
      end
    end

    describe "the non-MIVP rows" do
      let(:row_2) { assigns[:rows].second }
      let(:row_3) { assigns[:rows].third }

      it "has the proper data" do
        expect(row_2.length).to eq(4)
        expect(row_2.first.to_s).to eq(primary_account_2.to_s)
        expect(row_3.length).to eq(4)
        expect(row_3.first.to_s).to eq(primary_account_1.to_s)
      end
    end
  end

  describe "the account owner report" do
    before do
      sign_in administrator
      get :index, params: { report_by: :account_owner, date_start: 2.months.ago, date_end: Time.current,
                            status_filter: [OrderStatus.new_status], facility_id: facility.url_name,
                            date_range_field: "ordered_at" }, xhr: true
    end

    describe "the MIVP row" do
      let(:row) { assigns[:rows].last }

      it "has the proper data" do
        expect(row.length).to eq(4)
        expect(row.first.to_s).to eq("MIVP, MIVP (MIVP)")
      end
    end

    describe "the non-MIVP rows" do
      let(:row_1) { assigns[:rows].first }
      let(:row_2) { assigns[:rows].second }

      it "has the proper data" do
        expect(row_2.length).to eq(4)
        expect(row_2.first.to_s).to include(primary_account_2.owner_user.first_name)
        expect(row_1.length).to eq(4)
        expect(row_1.first.to_s).to include(primary_account_1.owner_user.first_name)
      end
    end
  end
end
