# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldApiClient do
  subject(:client) { described_class.new }

  describe "#unescape" do
    it "removes escape characters" do
      escaped_string = "-----BEGIN RSA KEY-----\\nABC123\\n456XYZ\\n-----END RSA KEY-----\\n"
      unescaped      = "-----BEGIN RSA KEY-----\nABC123\n456XYZ\n-----END RSA KEY-----\n"
      expect(client.unescape(escaped_string)).to eq unescaped
    end
  end

end
