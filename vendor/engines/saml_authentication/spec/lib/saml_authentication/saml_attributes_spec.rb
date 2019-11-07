# frozen_string_literal: true

require_relative "../../saml_spec_helper.rb"
require "saml_authentication/saml_attributes"

RSpec.describe SamlAuthentication::SamlAttributes do

  include_context "With SAML response"

  subject(:attributes) { described_class.new(saml_response) }

  it "makes the hash" do
    expect(attributes.to_h).to eq(
      "username" => "sst123",
      "email" => "sst123@example.com",
      "first_name" => "Sam",
      "last_name" => "Student",
    )
  end

  it "can access the values like a hash" do
    expect(attributes[:username]).to eq("sst123")
    expect(attributes[:email]).to eq("sst123@example.com")
  end

  it "can get every attribute" do
    expect(attributes.to_raw_h).to eq(
      "PersonImmutableID" => ["sst123"],
      "User.email" => ["sst123@example.com"],
      "User.FirstName" => ["Sam"],
      "User.LastName" => ["Student"],
      "memberOf" => [""]
    )
  end

end
