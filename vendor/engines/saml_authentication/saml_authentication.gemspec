# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "saml_authentication/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "saml_authentication"
  s.version     = SamlAuthentication::VERSION
  s.authors     = ["Table XI"]
  s.email       = ["devs@txidigital.com"]
  s.homepage    = "https://github.com/tablexi/nucore-open"
  s.summary     = "SAML Authentication for NUcore"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "devise_saml_authenticatable"
  s.add_dependency "rails", ">= 4.2"
end
