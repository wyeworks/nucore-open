require "rails_helper"
require_relative "../../saml_spec_helper.rb"

RSpec.describe SamlAuthentication::UserLocator do
  include_context "With SAML response"

  subject(:locator) { described_class.new }
  let(:result) { locator.call(User, saml_response, :unused) }
  it "does not find anything if the user does not exist" do
    expect(result).to be_blank
  end

  describe "when the user exists with the username" do
    let!(:user) { create(:user, username: "sst123") }

    it "finds the user" do
      expect(result).to eq(user)
    end
  end

  describe "when the user exists with the email" do
    let!(:user) { create(:user, email: "sst123@example.com") }

    it "finds the user" do
      expect(result).to eq(user)
    end
  end
end
