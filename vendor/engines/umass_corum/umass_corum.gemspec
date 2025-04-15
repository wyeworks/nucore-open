# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "umass_corum/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "umass_corum"
  s.version     = UmassCorum::VERSION
  s.authors     = ["Table XI"]
  s.email       = ["devs@tablexi.com"]
  s.homepage    = "http://www.github.com/tablexi/nucore-umass"
  s.summary     = "Customizations for UMass"
  s.description = "Customizations for UMass"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.metadata['rubygems_mfa_required'] = 'true'
end
