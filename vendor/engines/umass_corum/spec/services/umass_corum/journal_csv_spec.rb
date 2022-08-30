require "rails_helper"

RSpec.describe UmassCorum::Journals::JournalCsv do
  let(:user) { create(:user, username: "CCOLEMAN") }
  let(:facility) { create(:setup_facility, name: "Animal Imaging", abbreviation: "ANIMALIMAGING") }
  let(:product) { create(:setup_item, facility: facility) }
  let(:order) { create(:purchased_order, product: product) }
  let(:order_detail) { order.order_details.first }
  let(:zero_order_detail) { create(:order_detail, order: order, product: product) }
  let(:journal) do
    create(
      :journal,
      facility: facility,
      created_by_user: user,
      journal_date: Time.zone.parse("2020-08-20"),
    )
  end

  let!(:debit_journal_row) do
    create(
      :journal_row,
      journal: journal,
      order_detail: order_detail,
      ref_2: "ALS001",
      speed_type: 167998,
      account: 753080,
      trans_date: Time.zone.parse("2020-06-10"),
      description: "Name, Owner",
      amount: 350.01,
      name_reference: order_detail.order_number,
      doc_ref: "BME",
      fund: "53104",
      dept_id: "A091200002",
      program: "B03",
      project: "S11310000000076",
    )
  end
  let!(:credit_journal_row) do
    create(
      :journal_row,
      amount: -350.01,
      journal: journal,
      order_detail: nil,
    )
  end
  let!(:zero_debit_journal_row) do
    create(
      :journal_row,
      journal: journal,
      order_detail: zero_order_detail,
      ref_2: "ALS001",
      speed_type: 167998,
      account: 753080,
      trans_date: Time.zone.parse("2020-06-10"),
      description: "Name, Owner",
      amount: 0.0,
      name_reference: zero_order_detail.order_number,
      doc_ref: "BME",
      fund: "53104",
      dept_id: "A091200002",
      program: "B03",
      project: "S11310000000076",
    )
  end
  let!(:zero_credit_journal_row) do
    create(
      :journal_row,
      amount: -0.0,
      journal: journal,
      order_detail: nil
    )
  end

  let(:output) { described_class.new(journal).render }

  it "does not write a $0 row" do
    rows = output.split("\n")
    # 1 header, 1 debit row for 350.01, 1 credit row for -350.01
    expect(rows.count).to eq 3
  end

  it "writes the correct header row" do
    header = output.split("\n").first
    expect(header).to eq("Business Unit,Account,Speed Type,Fund,Dept,Program,Class,Project,Amount,Description,Name Reference,Trans Date,Doc Ref,Ref 2,Trans Ref")
  end

  it "writes the correct debit row" do
    row = output.split("\n").second
    expect(row).to eq("UMAMH,753080,167998,53104,A091200002,B03,,S11310000000076,350.01,\"Name, Owner\",#{order_detail},06/10/2020,BME,ALS001,ANIMALIMAGI")
  end

  it "writes the amount correctly for the credit row" do
    row = output.split("\n").third
    expect(row).to eq("UMAMH,99999,,,,,,,-350.01,,,\"\",,,ANIMALIMAGI")
  end
end
