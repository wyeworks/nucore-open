require "rails_helper"

RSpec.describe FullTextSearch::MysqlSearcher, if: Nucore::Database.mysql? do
  # We can't do this in a `before(:each)` block because the full text search index only
  # gets updated on commit and we're using transactions. Do not use factories to
  # ensure we don't end up with any zombie associations.
  before(:context) do
    facility = Facility.new(name: "name", abbreviation: "EF", url_name: "facility", is_active: true, short_description: "abc", journal_mask: "C01")
    facility.save(validate: false)
    item = Item.new(url_name: "lsc-andor", name: "LSC Andor Spinning Disk", facility: facility)
    item.save(validate: false)
  end

  after(:context) do
    Item.delete_all
    Facility.delete_all
    PriceGroupProduct.delete_all # these get created by an after_create callback on Products
  end

  let(:facility) { Facility.find_by(url_name: "facility") }
  let(:item) { Item.find_by!(url_name: "lsc-andor") }

  subject(:results) { described_class.new(Product.all).search([:name, :description], query) }

  context "when the query is nil" do
    let(:query) { nil }
    it { is_expected.to be_empty }
  end

  context "when the query is whitespace only" do
    let(:query) { " " }
    it { is_expected.to be_empty }
  end

  context "when the query matches no products" do
    let(:query) { "gobbledy gook" }
    it { is_expected.to be_empty }
  end

  context "when the query case does not match the db case" do
    let(:query) { "lsc" }
    it { is_expected.to contain_exactly(item) }
  end

  context "when it matches multiple words, but not exactly" do
    before(:context) do
      facility = Facility.find_by(url_name: "facility")
      Item.new(name: "LSC Nikon A1RSi", facility: facility, url_name: "lsc_nikon").save(validate: false)
    end
    after(:context) do
      Item.find_by(url_name: "lsc_nikon").destroy
    end

    let(:item2) { Item.find_by(url_name: "lsc_nikon") }
    let(:query) { "lsc spinning disk" }

    it "matches both products with the one matching more words first" do
      is_expected.to eq([item, item2])
    end
  end

end
