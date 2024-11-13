require "rails_helper"

RSpec.describe UmassCorum::Journals::JournalPrn do
  let(:user) { create(:user, username: "CCOLEMAN") }
  let(:facility) { create(:setup_facility, name: "Animal Imaging", abbreviation: "ANIMALIMAGING") }
  let(:product) { create(:setup_item, facility: facility) }
  let(:order) { create(:order, id: 1186, user: user, created_by: user.id) }

  let(:order_detail) { create(:order_detail, id: 1099, order: order, product: product) }
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
      trans_id: facility.abbreviation,
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
      trans_id: facility.abbreviation,
    )
  end
  let!(:zero_debit_journal_row) do
    create(
      :journal_row,
      journal: journal,
      order_detail: zero_order_detail,
      ref_2: "ALS001",
      trans_id: facility.abbreviation,
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
      order_detail: nil,
      trans_id: facility.abbreviation,
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
    expect(header).to eq("$$$ALS00108202020Animal Imaging    0000200000070002   CCOLEMAN                              UMAMH")
  end

  it "writes the correct debit row" do
    row = output.split("\n").second
    expect(row).to eq("   167998753080ANIMALI06102020Name, Owner         00000035001DALS001 ANIMALIMAGIUMAMH       #{order_detail}           BME      53104A091200002B03       S11310000000076")
  end

  it "writes the amount correctly for the credit row" do
    row = output.split("\n").third
    expect(row).to include("00000035001C")
  end

  it "writes the trans_id correctly for the credit row" do
    row = output.split("\n").third
    expect(row).to include(facility.abbreviation.first(11))
  end
end
