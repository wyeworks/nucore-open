# frozen_string_literal: true

# Some schools might override the default behavior, so fall back to that behavior
# so our tests can assume the original behavior. We test the custom behavior within
# the school's engine.
RSpec.shared_context "with default JournalRow converters" do
  before(:each) do
    allow(Converters::ConverterFactory).to receive(:for).with("order_detail_to_journal_rows").and_return(Converters::OrderDetailToJournalRowAttributes)
    allow(Converters::ConverterFactory).to receive(:for).with("product_to_journal_rows").and_return(Converters::ProductToJournalRowAttributes)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with default JournalRow converters", :default_journal_row_converters
end
