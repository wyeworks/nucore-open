require "rails_helper"

RSpec.describe Journal do
  let(:facility) { create(:setup_facility) }
  let(:journal_date) { Time.zone.now }
  let(:owner) { create(:user, first_name: "I have a very large first name that should overflow the field", last_name: "Ln") }

  let(:api_speed_type) { create(:api_speed_type, speed_type: "123456", dept_desc: "Polymer-User,Owner") }
  let(:recharge_speed_type) { create(:api_speed_type, :recharge, speed_type: "543210") }

  let(:account) { create(:speed_type_account, :with_account_owner, account_number: api_speed_type.speed_type, owner: owner) }
  let(:order) { create(:purchased_order, product: product, account: account) }
  let(:order_details) { order.order_details }
  let(:order_detail) { order_details.first }
  let(:recharge_account) { create(:facility_account, facility: facility, account_number: recharge_speed_type.speed_type) }
  let(:product) { create(:setup_item, facility: facility, facility_account: recharge_account, account: "753080") }

  before do
    order_details.each(&:to_complete!)
  end

  subject(:journal) do
    described_class.new(facility: facility, journal_date: journal_date, order_details_for_creation: order_details, created_by: 0)
  end

  it "creates the charge row" do
    expect { journal.save! }.to change(JournalRow, :count).by(2)
    expect(JournalRow.first).to have_attributes(
      business_unit: "UMAMH",
      account: "753080",
      speed_type: "123456",
      fund: "11000",
      dept_id: "A010400000",
      program: "B03",
      project: "S17110000000118",
      trans_ref: be_blank,
      amount: be_positive,
      description: "Ln, I have a very la",
      name_reference: order_detail.order_number,
      trans_date: order_detail.fulfilled_at,
      doc_ref: "Polymer",
      ref_2: /ALS\d{3}/,
      trans_id: facility.abbreviation,
      order_detail: order_details.first,
      account_id: account.id,
      trans_3rd_ref: be_blank,
    )
  end

  it "creates the recharge row" do
    expect { journal.save! }.to change(JournalRow, :count).by(2)
    expect(JournalRow.second).to have_attributes(
      business_unit: "UMAMH",
      account: "699900",
      speed_type: "543210",
      fund: "11000",
      dept_id: "A010400000",
      program: "D06",
      project: be_blank,
      trans_ref: be_blank,
      amount: be_negative,
      description: "Ln, I have a very la",
      name_reference: order_detail.order_number,
      trans_date: order_detail.fulfilled_at,
      doc_ref: "Polymer",
      ref_2: /ALS\d{3}/,
      trans_id: facility.abbreviation,
      account_id: be_blank,
      order_detail: be_blank, # Recharges are not tied to an order detail, only the expenses
      trans_3rd_ref: api_speed_type.speed_type,
    )
  end

  describe "with SubsidyAccount" do
    let(:account) do
      create(:subsidy_account, :with_account_owner,
             account_number: create(
               :speed_type_account,
               :with_account_owner,
               account_number: api_speed_type.speed_type,
               owner: owner).account_number
      )
    end

    let(:funding_source) { account.funding_source }

    it "creates the charge row with the funding source account number and account owner's name" do
      expect { journal.save! }.to change(JournalRow, :count).by(2)
      expect(JournalRow.first).to have_attributes(
        speed_type: funding_source.account_number,
        description: account.owner.user.last_first_name,
      )
    end
  end

  describe "with a second order detail" do
    let(:order2) { create(:purchased_order, product: product, account: account) }
    let(:order_details) { order.order_details + order2.order_details }

    it "creates two rows for each order detail" do
      expect { journal.save! }.to change(JournalRow, :count).by(4)
    end
  end

  describe "when the order is on a split account" do
    let(:account) { create(:split_account, splits: splits) }
    let(:subaccount1) { create(:speed_type_account, :with_account_owner, :with_api_speed_type, owner: owner) }
    let(:subaccount2) { create(:speed_type_account, :with_account_owner, :with_api_speed_type, owner: owner) }
    let(:splits) do
      [
        create(:split, subaccount: subaccount1, percent: 50, apply_remainder: true),
        create(:split, subaccount: subaccount2, percent: 50, apply_remainder: false),
      ]
    end

    it "creates 4 rows with the correct splits" do
      expect { journal.save! }.to change(JournalRow, :count).by(4)
      expect(journal.journal_rows.map(&:amount)).to eq([
        order_detail.actual_cost / 2, # First split
        - order_detail.actual_cost / 2, # First split recharge
        order_detail.actual_cost / 2, # Second split
        - order_detail.actual_cost / 2, # Second split recharge
      ])
    end

    it "splits the accounts" do
      journal.save!
      expect(journal.journal_rows.map(&:account_id)).to eq(
        [subaccount1.id, nil, subaccount2.id, nil]
      )
    end
  end

  describe "#als_number" do
    let!(:old_journal_1) { create(:journal, :with_completed_order, facility: facility, journal_date: 1.month.ago, created_by: 0, ) }
    let!(:old_journal_2) { create(:journal, :with_completed_order, facility: facility, journal_date: 2.months.ago, created_by: 0, ) }
    let!(:old_journal_3) { create(:journal, :with_completed_order, facility: facility, journal_date: 3.months.ago, created_by: 0, ) }
    let(:old_journal_4) { build(:journal, :with_completed_order, facility: facility, journal_date: 4.months.ago, created_by: 0, ) }
    let!(:journal_1) { create(:journal, facility: facility, journal_date: journal_date, order_details_for_creation: order_details, created_by: 0) }
    let!(:journal_2) { create(:journal, facility: facility, journal_date: journal_date, order_details_for_creation: order_details, created_by: 0) }
    let!(:journal_3) { create(:journal, facility: facility, journal_date: journal_date, order_details_for_creation: order_details, created_by: 0) }
    let(:journal_4) { build(:journal, facility: facility, journal_date: journal_date, order_details_for_creation: order_details, created_by: 0) }

    it "sets the als_number field sequentially by fiscal year" do
      expect(old_journal_1.als_number).to eq 1
      expect(old_journal_2.als_number).to eq 2
      expect(old_journal_3.als_number).to eq 3
      expect(journal_1.als_number).to eq 1
      expect(journal_2.als_number).to eq 2
      expect(journal_3.als_number).to eq 3
    end

    describe "when the max_value for als_number is reached" do
      before { journal_3.update_attribute(:als_number, 999) }

      it "is invalid" do
        journal_4.save
        expect(journal_4).not_to be_persisted
        expect(journal_4.errors).to include(:als_number)
      end
    end

    describe "when there are gaps in the als_number sequence" do
      before { journal_3.update_attribute(:als_number, 95) }

      it "increments from the highest als_number in the fiscal_year" do
        journal_4.save
        expect(journal_4).to be_persisted
        expect(journal_4.als_number).to eq 96
      end
    end

    describe "when creating a journal for a previous fiscal year" do
      before { journal_3.update_attribute(:als_number, 95) }

      it "increments from the highest als_number in the previous fiscal_year" do
        old_journal_4.save
        expect(old_journal_4).to be_persisted
        expect(old_journal_4.als_number).to eq 4
      end
    end

    describe "when the als_number already exists in the fiscal year" do
      before { journal_3.update(als_number: journal_2.als_number) }

      it "is invalid" do
        expect(journal_3.errors.map(&:full_message)).to include("Als number can only be used once per fiscal year")
      end

      it "is rejected by the database" do
        expect{ journal_3.update_attribute(:als_number, journal_2.als_number) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

  end

  describe "#als_prefix" do

    context "with data-corps facility" do
      let(:facility) { create(:setup_facility, url_name: "data-corps") }

      it "prefixes DCR for data-corps facility" do
        expect { journal.save! }.to change(JournalRow, :count).by(2)
        expect(JournalRow.second).to have_attributes(
          ref_2: /DCR\d{3}/,
        )
      end
    end

    context "with gel-permeation-chromatography facility" do
      let(:facility) { create(:setup_facility, url_name: "gel-permeation-chromatography") }

      it "prefixes GPC for gel-permeation-chromatography facility" do
        expect { journal.save! }.to change(JournalRow, :count).by(2)
        expect(JournalRow.second).to have_attributes(
          ref_2: /GPC\d{3}/,
        )
      end
    end

    context "with proposal-support-services facility" do
      let(:facility) { create(:setup_facility, url_name: "proposal-support-services") }

      it "prefixes PSS for proposal-support-services facility" do
        expect { journal.save! }.to change(JournalRow, :count).by(2)
        expect(JournalRow.second).to have_attributes(
          ref_2: /PSS\d{3}/,
        )
      end

    end
  end

end
