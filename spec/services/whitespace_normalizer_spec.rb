# frozen_string_literal: true

require "rails_helper"

RSpec.describe WhitespaceNormalizer do
  it "changes spaces and tabs" do
    input = "a test\tof tabs"
    expect(described_class.normalize(input)).to eq("a test of tabs")
  end

  it "changes em and en unicode spaces" do
    input = "enspace\u2002followed by\u2003emspace"
    expect(described_class.normalize(input)).to eq("enspace followed by emspace")
  end

  it "changes a bunch of other characters" do
    characters = [
      "\u2007", # figure space
      "\u2008", # punctuatin space
      "\u2009", # thin space
      "\u200A", # hair space
      "\u2000", # zero-width space
      "\u00A0", # non-breaking space
    ]
    input = characters.join

    expect(described_class.normalize(input)).to eq(" " * characters.length)
  end

  it "leaves new lines alone" do
    input = "with\nsome\nnew\nlines"
    expect(described_class.normalize(input)).to eq(input)
  end

  it "converts carriage returns to newlines" do
    input = "with\rsome\rcarriage\rreturns"
    expect(described_class.normalize(input)).to eq("with\nsome\ncarriage\nreturns")
  end

  it "converts NL+CR to a single newline" do
    input = "with\n\rsome\r\nbreaks"
    expect(described_class.normalize(input)).to eq("with\nsome\nbreaks")
  end

  it "cleans up unicode line separator" do
    input = "with\u2028a line separator"
    expect(described_class.normalize(input)).to eq("with\na line separator")
  end

  it "doesn't choke on nil" do
    input = nil
    expect(described_class.normalize(input)).to eq(nil)
  end
end
