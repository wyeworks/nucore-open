# frozen_string_literal: true
require "devise_saml_authenticatable/saml_response"

RSpec.shared_context "With SAML response" do
  let(:saml_response) do
    string = Base64.encode64(File.read(File.expand_path("../../fixtures/login_response.xml", __dir__)))
    ruby_saml_response = OneLogin::RubySaml::Response.new(string)
    ::SamlAuthenticatable::SamlResponse.new(ruby_saml_response, saml_attribute_map)
  end

  let(:saml_attribute_map) do
    {
      "PersonImmutableID" => "username",
      "User.email" => "email",
      "User.FirstName" => "first_name",
      "User.LastName" => "last_name",
    }
  end
end
