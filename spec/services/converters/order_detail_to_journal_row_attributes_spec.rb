# frozen_string_literal: true

require "rails_helper"

RSpec.describe Converters::OrderDetailToJournalRowAttributes, type: :service do

  let(:converter) { described_class.new(journal, order_detail) }
  let(:journal) { build_stubbed(:journal) }
  let(:order_detail) do
    build_stubbed(:order_detail).tap do |order_detail|
      allow(order_detail).to receive_message_chain(:product, :account) { "product_account" }
      allow(order_detail).to receive(:total) { 100 }
      allow(order_detail).to receive(:long_description) { "long_description" }
    end
  end

  it "initializes journal" do
    expect(converter.journal).to eq(journal)
  end

  it "initializes order_detail" do
    expect(converter.order_detail).to eq(order_detail)
  end

  describe "#convert" do
    let(:returned) { converter.convert }

    context "for first journal row" do
      it "sets account" do
        expect(returned[:account]).to eq(order_detail.product.account)
      end

      it "sets amount" do
        expect(returned[:amount]).to eq(order_detail.total)
      end

      it "sets description" do
        expect(returned[:description]).to eq(order_detail.long_description)
      end

      it "sets order_detail_id" do
        expect(returned[:order_detail]).to eq(order_detail)
      end

      it "sets journal_id" do
        expect(returned[:journal]).to eq(journal)
      end
    end
  end

end
