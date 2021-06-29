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
      order_detail: order_details.first,
      account_id: account.id,
    )
  end

  it "sets the als_number field if feature flag is set", feature_setting: { als_number_generator: true } do
    journal.save!
    expect(journal.als_number).not_to be_nil
  end

  it "does not set the als_number field if feature flag is false", feature_setting: { als_number_generator: false } do
    journal.save!
    expect(journal.als_number).to be_nil
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
      account_id: be_blank,
      order_detail: be_blank, # Recharges are not tied to an order detail, only the expenses
    )
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

  describe "when we have reached the max_value for als_number", feature_setting: { als_number_generator: true } do
    before do
      allow(::UmassCorum::Journals::AlsNumberGenerator::AlsSequenceNumber).to receive(:maximum).and_return(999)
    end
    
    it "should raise an error on create" do
      expect { journal.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(journal.id).to be_nil
    end
  end

end
