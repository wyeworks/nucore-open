require "spec_helper"

RSpec.describe UmassCorum::JournalParser do
  describe "parse" do
    let(:input) { File.read(File.expand_path("../../fixtures/journal_sample.prn", __dir__)) }
    subject(:output) { described_class.parse(input) }

    describe "header" do
      specify { expect(output.header[:trans_code]).to eq("$$$") }
      specify { expect(output.header[:um_batch_id]).to eq("ALS095") }
      specify { expect(output.header[:batch_date]).to eq(Date.parse("2019-10-03")) }
      specify { expect(output.header[:batch_desc]).to eq("Light Microscop") }
      specify { expect(output.header[:jml_type]).to be_blank }
      specify { expect(output.header[:batch_user_code]).to be_blank }
      specify { expect(output.header[:batch_trans_count]).to eq(74) }
      specify { expect(output.header[:batch_trans_amount]).to eq(BigDecimal("14392.58")) }
      specify { expect(output.header[:batch_susp_id]).to be_blank }
      specify { expect(output.header[:batch_originator]).to eq("ELNUGENT") }
      specify { expect(output.header[:batch_business_unit]).to eq("UMAMH") }
    end

    describe "first row" do
      let(:row) { output.first }
      specify { expect(row[:trans_code]).to be_blank }
      specify { expect(row[:speedtype]).to eq("155308") }
      specify { expect(row[:account]).to eq("753080") }
      specify { expect(row[:trans_ref]).to eq("LM19111") }
      specify { expect(row[:trans_date]).to eq(Date.parse("2019-06-17")) }
      specify { expect(row[:trans_desc]).to eq("Carter, Kenneth") }
      specify { expect(row[:amount]).to eq(BigDecimal("67.50")) }
      specify { expect(row[:credit_debit]).to eq("D") }
      specify { expect(row[:trans_2nd_ref]).to eq("ALS095") }
      specify { expect(row[:trans_id]).to be_blank }
      specify { expect(row[:campus_business_unit]).to eq("UMAMH") }
      specify { expect(row[:trans_3rd_ref]).to be_blank }
      specify { expect(row[:name]).to eq("Light Micro") }
      specify { expect(row[:doc_reference]).to eq("PSE") }
      specify { expect(row[:fund_code]).to eq("53106") }
      specify { expect(row[:department_id]).to eq("A090700034") }
      specify { expect(row[:program_code]).to eq("B03") }
      specify { expect(row[:class_code]).to be_blank }
      specify { expect(row[:project_id]).to eq("S12100000001075") }
    end

    describe "second row" do
      let(:row) { output.drop(1).first }

      specify { expect(row[:trans_code]).to be_blank }
      specify { expect(row[:speedtype]).to eq("155226") }
      specify { expect(row[:account]).to eq("699900") }
      specify { expect(row[:trans_ref]).to eq("LM19111") }
      specify { expect(row[:trans_date]).to eq(Date.parse("2019-06-17")) }
      specify { expect(row[:trans_desc]).to eq("Carter, Kenneth") }
      specify { expect(row[:amount]).to eq(BigDecimal("67.50")) }
      specify { expect(row[:credit_debit]).to eq("C") }
      specify { expect(row[:trans_2nd_ref]).to eq("ALS095") }
      specify { expect(row[:trans_id]).to be_blank }
      specify { expect(row[:campus_business_unit]).to eq("UMAMH") }
      specify { expect(row[:trans_3rd_ref]).to be_blank }
      specify { expect(row[:name]).to eq("Light Micro") }
      specify { expect(row[:doc_reference]).to eq("PSE") }
      specify { expect(row[:fund_code]).to eq("51511") }
      specify { expect(row[:department_id]).to eq("A606363000") }
      specify { expect(row[:program_code]).to eq("D06") }
      specify { expect(row[:class_code]).to be_blank }
      specify { expect(row[:project_id]).to be_blank }
    end
  end
end
