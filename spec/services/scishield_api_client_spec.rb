# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldApiClient do
  subject(:client) { described_class.new }
  let!(:user) { create(:user, email: "Todd.Miller@oregonstate.edu") }
  let(:email) { user.email }
  let(:api_endpoint) { client.api_endpoint(user.email) }
  let(:response) { File.expand_path("../fixtures/scishield/success.json", __dir__) }
  let(:empty_response) { File.expand_path("../fixtures/scishield/empty_success.json", __dir__) }
  let(:api_response) { response }
  let(:http_status) { 200 }

  describe "#unescape" do
    it "removes escape characters" do
      escaped_string = "-----BEGIN RSA KEY-----\\nABC123\\n456XYZ\\n-----END RSA KEY-----\\n"
      unescaped      = "-----BEGIN RSA KEY-----\nABC123\n456XYZ\n-----END RSA KEY-----\n"
      expect(client.unescape(escaped_string)).to eq unescaped
    end
  end

  describe "#invalid_response?" do
    before do
      stub_request(:get, api_endpoint)
        .to_return(
          status: http_status,
          body: File.new(api_response)
        )
    end

    context "when the response is valid" do
      it "returns false" do
        expect(client.invalid_response?(email)).to be_falsy
      end
    end

    context "when the HTTP status is an error" do
      context "when the HTTP status is 500" do
        let(:http_status) { 500 }

        it "is invalid" do
          expect(client.invalid_response?(email)).to be_truthy
        end
      end
    end

    context "when the data is empty" do
      let(:api_response) { empty_response }

      it "is invalid" do
        expect(client.invalid_response?(email)).to be_truthy
      end
    end
  end
end
