require "rails_helper"

RSpec.describe Journals::JournalFormat do
  let(:settings) do
    [
      { key: "csv", class_name: "Journals::DefaultJournalCsv" },
      { key: "xls" },
      { key: "rnd", class_name: "Journals::DefaultJournalCsv", mime_type: :text },
    ]
  end

  before do
    allow(Settings.financial).to receive(:journal_format).and_return(settings)
  end

  describe ".all" do
    it "has three items" do
      expect(described_class.all.length).to eq(3)
    end

    it "has the keys" do
      expect(described_class.all.map(&:key)).to contain_exactly("csv", "xls", "rnd")
    end
  end

  describe ".find" do
    it "finds the key by a symbol" do
      result = described_class.find(:xls)
      expect(result).to be_present
      expect(result.key).to eq("xls")
    end

    it "finds the key by a string" do
      result = described_class.find("xls")
      expect(result).to be_present
      expect(result.key.to_s).to eq("xls")
    end

    it "returns nothing if not found" do
      result = described_class.find("unknown")
      expect(result).to be_blank
    end
  end

  describe ".exists?" do
    it "returns true for a key that matches" do
      expect(described_class.exists?(:xls)).to be(true)
    end

    it "returns false for a key that doesn't match" do
      expect(described_class.exists?(:unknown)).to be(false)
    end
  end

  describe "options" do
    it "defaults to a regular mime type" do
      format = described_class.new(key: :csv)
      expect(format.options[:mime_type]).to eq("text/csv")
    end

    it "can override the mime" do
      format = described_class.new(key: :csv, mime_type: :html)
      expect(format.options[:mime_type]).to eq("text/html")
    end

    it "defaults a filename" do
      format = described_class.new(key: :csv)
      expect(format.options[:filename]).to eq("journal.csv")
    end

    it "can override the filename" do
      format = described_class.new(key: :csv, filename: "abcxy.txt")
      expect(format.options[:filename]).to eq("abcxy.txt")
    end
  end

end
