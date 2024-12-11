require "spec_helper"

RSpec.describe UmassCorum::JournalWriter do
  it "writes the headers" do
    header_row = described_class.new(
      headers: {
        trans_code: "$$$",
        um_batch_id: "ALS095",
        batch_date: Date.parse("2019-10-03"),
        batch_desc: "Light Mi",
        batch_trans_count: 74,
        batch_trans_amount: BigDecimal("14392.58"),
        batch_originator: "ELNUGENT",
        batch_business_unit: "UMAMH",
      }
    ).header_row
    expect(header_row).to eq("$$$ALS09510032019Light Mi          0007400001439258   ELNUGENT                              UMAMH")
  end

  it "writes a row" do
    journal = described_class.new
    journal << {
      speedtype: "155308",
      account: "753080",
      trans_ref: "LM19111",
      trans_date: Date.parse("2019-06-17"),
      trans_desc: "Carter, Kenneth",
      amount: BigDecimal("67.50"),
      credit_debit: "D",
      trans_2nd_ref: "ALS095",
      campus_business_unit: "UMAMH",
      name: "Light Micro",
      doc_reference: "PSE",
      fund_code: "53106",
      department_id: "A090700034",
      program_code: "B03",
      project_id: "S12100000001075",
    }
    expect(journal.rows.first).to eq("   155308753080LM1911106172019Carter, Kenneth     00000006750DALS095            UMAMH       Light Micro         PSE      53106A090700034B03       S12100000001075")
  end

  it "writes multiple rows" do
    journal = described_class.new
    journal << {}
    journal << {
      speedtype: "155226",
      account: "699900",
      trans_ref: "LM19111",
      trans_date: Date.parse("2019-06-17"),
      trans_desc: "Carter, Kenneth",
      amount: BigDecimal("67.50"),
      credit_debit: "C",
      trans_2nd_ref: "ALS095",
      campus_business_unit: "UMAMH",
      name: "Light Micro",
      doc_reference: "PSE",
      fund_code: "51511",
      department_id: "A606363000",
      program_code: "D06",
    }
    expect(journal.rows.drop(1).first).to eq("   155226699900LM1911106172019Carter, Kenneth     00000006750CALS095            UMAMH       Light Micro         PSE      51511A606363000D06                      ")
  end
end
