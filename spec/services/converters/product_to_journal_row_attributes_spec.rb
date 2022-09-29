# frozen_string_literal: true

require "rails_helper"

RSpec.describe Converters::ProductToJournalRowAttributes, type: :service do

  let(:converter) { described_class.new(journal, product, total) }
  let(:journal) { build_stubbed(:journal) }
  let(:product) do
    build_stubbed(:product).tap do |product|
      allow(product).to receive_message_chain(:facility_account, :revenue_account_for_journal) { "revenue_account" }
    end
  end
  let(:total) { 100 }

  it "initializes journal" do
    expect(converter.journal).to eq(journal)
  end

  it "initializes product" do
    expect(converter.product).to eq(product)
  end

  it "initializes total" do
    expect(converter.total).to eq(total)
  end

  describe "#convert" do
    let(:returned) { converter.convert }

    context "for the journal row attributes" do

      it "sets account" do
        expect(returned[:account]).to eq(product.facility_account.revenue_account_for_journal)
      end

      it "sets amount" do
        expect(returned[:amount]).to eq(-100)
      end

      it "sets description" do
        expect(returned[:description]).to eq(product.to_s)
      end

      it "sets journal_id" do
        expect(returned[:journal_id]).to eq(journal.id)
      end
    end
  end

end
