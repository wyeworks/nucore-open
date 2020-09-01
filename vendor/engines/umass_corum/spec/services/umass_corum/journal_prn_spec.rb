require "rails_helper"

RSpec.describe UmassCorum::Journals::JournalPrn do
  let(:user) { build(:user, username: "CCOLEMAN") }
  let(:facility) { build(:facility, name: "Animal Imaging") }
  let(:journal) do
    build(
      :journal,
      facility: facility,
      journal_rows: [debit_journal_row, credit_journal_row],
      created_by_user: user,
      journal_date: Time.zone.parse("2020-08-20"),
    )
  end
  let(:order) { build(:order, id: 1186) }
  let(:order_detail) { build(:order_detail, id: 1099, order: order) }
  let(:debit_journal_row) do
    build(
      :journal_row,
      journal: nil,
      order_detail: order_detail,
      ref_2: "ALS001",
      speed_type: 167998,
      account: 753080,
      trans_date: Time.zone.parse("2020-06-10"),
      description: "Name, Owner",
      amount: 350.01,
      name_reference: order_detail.to_s,
      doc_ref: "BME",
      fund: "53104",
      dept_id: "A091200002",
      program: "B03",
      project: "S11310000000076",
    )
  end
  let(:credit_journal_row) do
    build(
      :journal_row,
      amount: -350.01,
      journal: nil,
      order_detail: nil
    )
  end

  let(:output) { described_class.new(journal).render }

  it "writes the correct header row" do
    header = output.split("\n").first
    expect(header).to eq("$$$ALS00108202020Animal Imaging    0000200000070002   CCOLEMAN                              UMAMH")
  end

  it "writes the correct debit row" do
    row = output.split("\n").second
    expect(row).to eq("    167998753080       06102020Name, Owner         00000035001DALS001            UMAMH       1186-1099           BME      53104A091200002B03       S11310000000076")
  end

  it "writes the amount correctly for the credit row" do
    row = output.split("\n").third
    expect(row).to include("00000035001C")
  end
end
