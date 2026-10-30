# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "ldap_authentication/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ldap_authentication"
  s.version     = LdapAuthentication::VERSION
  s.authors     = ["Table XI"]
  s.email       = ["devs@txidigital.com"]
  s.homepage = "https://github.com/tablexi/nucore-open"
  s.summary     = "LDAP Authentication for NUcore"
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  s.add_dependency "devise_ldap_authenticatable", ">= 0.8.6"
  s.add_dependency "rails", ">= 4.2"
  s.metadata["rubygems_mfa_required"] = "true"
end
